//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

struct GeoLabelsWithIntersections {
    let intersections: [Int: [LabelIntersection]]
    let geoLabels: [MetalGeoLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

class ScreenCollisionsDetector {
    private struct SortedGeoLabel {
        let i: Int
        let screenPositions: SIMD2<Float>
        let mapLabelLineCollisionsMeta: MapLabelLineCollisionsMeta
    }
    
    private let computeLabelScreen: ComputeLabelScreen
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private var projectPoints: ProjectPoints!
    
    private let inputBufferWorldPostionsSize = 1500
    private let modelMatrixBufferSize = 60
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    
    // самые актуальные надписи карты
    // для них мы считаем коллизии
    private var geoLabels: [MetalGeoLabels] = []
    private var geoLabelsTimePoints: [Float] = []
    private var actualLabelsIds: Set<UInt> = []
    
    // закэшированные надписи и результат отработки вычисления пересечений
    private var geoLabelsWithIntersections: GeoLabelsWithIntersections = GeoLabelsWithIntersections(
        intersections: [:], geoLabels: [], bufferingCounter: 0
    )
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if geoLabelsWithIntersections.bufferingCounter <= 0 { return nil }
        
        geoLabelsWithIntersections.bufferingCounter -= 1
        return geoLabelsWithIntersections
    }
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.projectPoints = ProjectPoints(
            computeLabelScreen: computeLabelScreen,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
    }
    
    private func onPointsReady(result: ProjectPoints.Result) {
        let output = result.output
        let mapLabelLineCollisionsMeta = result.input.mapLabelLineCollisionsMeta
        let actualLabelsIdsCaching = result.input.actualLabelsIds
        let metalGeoLabels = result.input.metalGeoLabels
        
        
        var sortedGeoLabels: [SortedGeoLabel] = []
        sortedGeoLabels.reserveCapacity(output.count)
        for i in 0..<output.count {
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
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
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
            return true // recompute is needed again but later
        }
        
        var inputComputeScreenVertices: [InputComputeScreenVertex] = []
        
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
        
//        inputComputeScreenVertices.append(contentsOf: Array(
//            repeating: InputComputeScreenVertex(location: SIMD2<Float>(1, 1), matrixId: 0),
//            count: 100
//        ))
        
        projectPoints.project(input: ProjectPoints.ProjectInput(
            modelMatrices: modelMatrices,
            uniforms: lastUniforms,
            inputComputeScreenVertices: inputComputeScreenVertices,
            
            metalGeoLabels: metalGeoLabels,
            mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
            actualLabelsIds: actualLabelsIds
        ))
        
        return false
    }
}
