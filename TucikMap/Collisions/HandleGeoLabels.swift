//
//  HandleGeoLabels.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit

class HandleGeoLabels {
    struct ForEvaluationResult {
        let recallLater: Bool
        let inputComputeScreenVertices: [InputComputeScreenVertex]
        let mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta]
        let modelMatrices: [matrix_float4x4]
        let metalGeoLabels: [MetalGeoLabels]
        let geoLabelsSize: Int
    }
    
    private struct SortedGeoLabel {
        let i: Int
        let screenPositions: SIMD2<Float>
        let mapLabelLineCollisionsMeta: MapLabelLineCollisionsMeta
    }
    
    private let modelMatrixBufferSize = 60
    
    // самые актуальные надписи карты
    // для них мы считаем коллизии
    private var geoLabels: [MetalGeoLabels] = []
    private var geoLabelsTimePoints: [Float] = []
    var actualLabelsIds: Set<UInt> = []
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    
    // закэшированные надписи и результат отработки вычисления пересечений
    private var geoLabelsWithIntersections: GeoLabelsWithIntersections = GeoLabelsWithIntersections(
        intersections: [:], geoLabels: [], bufferingCounter: 0
    )
    
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private let mapZoomState: MapZoomState
    
    init(frameCounter: FrameCounter, mapZoomState: MapZoomState, renderFrameCount: RenderFrameCount) {
        self.frameCounter = frameCounter
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
    }
    
    func onPointsReady(result: ProjectPoints.Result) {
        let output = result.output
        let mapLabelLineCollisionsMeta = result.input.mapLabelLineCollisionsMeta
        let actualLabelsIdsCaching = result.input.actualLabelsIds
        let metalGeoLabels = result.input.metalGeoLabels
        let geoLabelsSize = result.input.geoLabelsSize
        
        var sortedGeoLabels: [SortedGeoLabel] = []
        sortedGeoLabels.reserveCapacity(output.count)
        for i in 0..<geoLabelsSize {
            let screenPositions = output[i]
            let mapLabelLineCollisionsMeta = mapLabelLineCollisionsMeta[i]
            sortedGeoLabels.append(SortedGeoLabel(
                i: i,
                screenPositions: screenPositions,
                mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
            ))
        }
        sortedGeoLabels.sort(by: { first, second in first.mapLabelLineCollisionsMeta.sortRank < second.mapLabelLineCollisionsMeta.sortRank })
        
        
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        var labelIntersections = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: output.count)
        var handledActualGeoLabels: Set<UInt> = []
        for sorted in sortedGeoLabels {
            let screenPositions = sorted.screenPositions
            let metaLine = sorted.mapLabelLineCollisionsMeta
            let collisionId = metaLine.id
            let isActualLabel = actualLabelsIdsCaching.contains(collisionId)
            
            if isActualLabel == false {
                let labelIntersection: LabelIntersection
                if let previousState = self.savedLabelIntersections[collisionId] {
                    let isHideAlready = previousState.hide == true
                    let createdTime = isHideAlready ? previousState.createdTime : elapsedTime
                    labelIntersection = LabelIntersection(hide: true, createdTime: createdTime)
                } else {
                    labelIntersection = LabelIntersection(hide: true, createdTime: elapsedTime)
                }
                
                labelIntersections[sorted.i] = labelIntersection
                self.savedLabelIntersections[collisionId] = labelIntersection
                continue
            }
            
            if handledActualGeoLabels.contains(collisionId) {
                labelIntersections[sorted.i] = self.savedLabelIntersections[collisionId]!
                continue
            }
            handledActualGeoLabels.insert(collisionId)
            
            let added = spaceDiscretisation.addAgent(agent: CollisionAgent(
                location: SIMD2<Float>(Float(screenPositions.x + 5000), Float(screenPositions.y + 5000)),
                height: Float((abs(metaLine.measuredText.top) + abs(metaLine.measuredText.bottom)) * metaLine.scale),
                width: Float(metaLine.measuredText.width * metaLine.scale)
            ))
            
            let hide = added == false
            let labelIntersection: LabelIntersection
            if let previousState = self.savedLabelIntersections[collisionId] {
                let statusChanged = hide != previousState.hide
                let createdTime = statusChanged ? elapsedTime : previousState.createdTime
                labelIntersection = LabelIntersection(hide: hide, createdTime: createdTime)
            } else {
                labelIntersection = LabelIntersection(hide: hide, createdTime: elapsedTime)
            }
            
            labelIntersections[sorted.i] = labelIntersection
            self.savedLabelIntersections[collisionId] = labelIntersection
        }
        
        var intersectionsResultByTiles: [Int: [LabelIntersection]] = [:]
        var startIndex = 0
        for i in 0..<metalGeoLabels.count {
            let tile = metalGeoLabels[i]
            guard let textLabels = tile.textLabels else { continue }
            let count = textLabels.mapLabelLineCollisionsMeta.count
            let subArray = Array(labelIntersections[startIndex ..< startIndex + count])
            
            intersectionsResultByTiles[i] = subArray
            startIndex += count
        }
        
        self.geoLabelsWithIntersections = GeoLabelsWithIntersections(
            intersections: intersectionsResultByTiles,
            geoLabels: metalGeoLabels
        )
        
        self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
    }
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if geoLabelsWithIntersections.bufferingCounter <= 0 { return nil }
        
        geoLabelsWithIntersections.bufferingCounter -= 1
        return geoLabelsWithIntersections
    }
    
    func forEvaluateCollisions(
        mapPanning: SIMD3<Double>
    ) -> ForEvaluationResult {
        var inputComputeScreenVertices: [InputComputeScreenVertex] = []
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        var metalGeoLabels: [MetalGeoLabels] = []
        // Удаляет стухшие тайлы с гео метками
        for geoLabel in self.geoLabels {
            if geoLabel.timePoint == nil || elapsedTime - geoLabel.timePoint! < Settings.labelsFadeAnimationTimeSeconds {
                metalGeoLabels.append(geoLabel)
            }
        }
        self.geoLabels = metalGeoLabels
        if self.geoLabels.count > modelMatrixBufferSize {
            // если быстро зумить камеру туда/cюда то geoLabels будет расти в размере из-за того что анимация не успевает за изменениями
            // в таком случае пропускаем изменения и отображаем старые данные до тех пор пока пользователь не успокоиться
            //renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight) // продолжаем рендрить чтобы обновились данные в конце концов
            return ForEvaluationResult(
                recallLater: true,
                inputComputeScreenVertices: [],
                mapLabelLineCollisionsMeta: [],
                modelMatrices: [],
                metalGeoLabels: [],
                geoLabelsSize: 0
            ) // recompute is needed again but later
        }
        
        var modelMatrices = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        var mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta] = []
        for i in 0..<metalGeoLabels.count {
            let tile = metalGeoLabels[i]
            let tileModelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            modelMatrices[i] = tileModelMatrix
            
            guard let textLabels = tile.textLabels else { continue }
            let inputArray = textLabels.mapLabelLineCollisionsMeta.map {
                label in InputComputeScreenVertex(location: label.localPosition, matrixId: simd_short1(i))
            }
            inputComputeScreenVertices.append(contentsOf: inputArray)
            mapLabelLineCollisionsMeta.append(contentsOf: textLabels.mapLabelLineCollisionsMeta)
        }
        
        return ForEvaluationResult(
            recallLater: false,
            inputComputeScreenVertices: inputComputeScreenVertices,
            mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
            modelMatrices: modelMatrices,
            metalGeoLabels: metalGeoLabels,
            geoLabelsSize: inputComputeScreenVertices.count
        )
    }
    
    func setGeoLabels(geoLabels: [MetalGeoLabels]) {
        guard geoLabels.isEmpty == false else { return }
        let elapsedTime = frameCounter.getElapsedTimeSeconds()
        
        let currentZ = geoLabels.first!.tile.z
        var savePrevious: [MetalGeoLabels] = []
        for label in self.geoLabels {
            let isDifferentZ = label.tile.z != currentZ
            if isDifferentZ {
                label.timePoint = elapsedTime
                savePrevious.append(label)
            }
        }
        
        // ресетит тайлы, делает их снова актуальными
        geoLabels.forEach { label in label.timePoint = nil }
        self.actualLabelsIds = Set(geoLabels.flatMap { label in label.containIds })
        self.geoLabels = geoLabels + savePrevious
    }
}
