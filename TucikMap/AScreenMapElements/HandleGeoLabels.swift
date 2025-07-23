//
//  HandleGeoLabels.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit


// Отвечает за отображение меток городов и стран
// опередляет какие показывать, а какие нет
// определяет сколько хранить метки тайла,а какие удалить
// определяет пересечения меток
class HandleGeoLabels {
    private struct SortedGeoLabel {
        let i: Int
        let screenPositions: SIMD2<Float>
        let mapLabelCpuMeta: MapLabelsAssembler.MapLabelCpuMeta
    }
    
    // самые актуальные надписи карты
    // для них мы считаем коллизии
    private var geoLabels: [MetalTile.TextLabels] = []
    private var geoLabelsTimePoints: [Float] = []
    var actualLabelsIds: Set<UInt> = []
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    
    // закэшированные надписи и результат отработки вычисления пересечений
    private var geoLabelsWithIntersections: GeoLabelsWithIntersections = GeoLabelsWithIntersections(
        intersections: [:], geoLabels: [], bufferingCounter: 0
    )
    
    private let frameCounter: FrameCounter
    private let mapZoomState: MapZoomState
    
    init(frameCounter: FrameCounter, mapZoomState: MapZoomState) {
        self.frameCounter = frameCounter
        self.mapZoomState = mapZoomState
    }
    
    func onPointsReady(result: CombinedCompSP.Result, spaceDiscretisation: SpaceDiscretisation) {
        let output                          = result.output
        let mapLabelLineCollisionsMeta      = result.mapLabelLineCollisionsMeta
        let actualLabelsIdsCaching          = result.actualLabelsIds
        let metalGeoLabels                  = result.metalGeoLabels
        let geoLabelsSize                   = result.geoLabelsSize
        
        var sortedGeoLabels: [SortedGeoLabel] = []
        sortedGeoLabels.reserveCapacity(geoLabelsSize)
        for i in 0..<geoLabelsSize {
            let screenPositions = output[i]
            let mapLabelLineCollisionsMeta = mapLabelLineCollisionsMeta[i]
            sortedGeoLabels.append(SortedGeoLabel(
                i: i,
                screenPositions: screenPositions,
                mapLabelCpuMeta: mapLabelLineCollisionsMeta,
            ))
        }
        sortedGeoLabels.sort(by: { first, second in first.mapLabelCpuMeta.sortRank < second.mapLabelCpuMeta.sortRank })
        
        
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        var labelIntersections = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: geoLabelsSize)
        var handledActualGeoLabels: Set<UInt> = []
        for sorted in sortedGeoLabels {
            let screenPositions     = sorted.screenPositions
            let metaLine            = sorted.mapLabelCpuMeta
            let labelId             = metaLine.id
            
            let isActualLabel       = actualLabelsIdsCaching.contains(labelId)
            if isActualLabel == false {
                let labelIntersection: LabelIntersection
                if let previousState = self.savedLabelIntersections[labelId] {
                    let isHideAlready = previousState.hide == true
                    let createdTime = isHideAlready ? previousState.createdTime : elapsedTime
                    labelIntersection = LabelIntersection(hide: true, createdTime: createdTime)
                } else {
                    labelIntersection = LabelIntersection(hide: true, createdTime: elapsedTime)
                }
                
                labelIntersections[sorted.i] = labelIntersection
                self.savedLabelIntersections[labelId] = labelIntersection
                continue
            }
            
            if handledActualGeoLabels.contains(labelId) {
                labelIntersections[sorted.i] = self.savedLabelIntersections[labelId]!
                continue
            }
            handledActualGeoLabels.insert(labelId)
            
            let added = spaceDiscretisation.addAgent(agent: CollisionAgent(
                location: SIMD2<Float>(Float(screenPositions.x), Float(screenPositions.y)),
                height: Float((abs(metaLine.measuredText.top) + abs(metaLine.measuredText.bottom)) * metaLine.scale),
                width: Float(metaLine.measuredText.width * metaLine.scale)
            ))
            
            let hide = added == false
            let labelIntersection: LabelIntersection
            if let previousState = self.savedLabelIntersections[labelId] {
                let statusChanged = hide != previousState.hide
                let createdTime = statusChanged ? elapsedTime : previousState.createdTime
                labelIntersection = LabelIntersection(hide: hide, createdTime: createdTime)
            } else {
                labelIntersection = LabelIntersection(hide: hide, createdTime: hide == true ? 0 : elapsedTime)
            }
            
            labelIntersections[sorted.i] = labelIntersection
            self.savedLabelIntersections[labelId] = labelIntersection
        }
        
        var intersectionsResultByTiles: [Int: [LabelIntersection]] = [:]
        var startIndex = 0
        for i in 0..<metalGeoLabels.count {
            let tile = metalGeoLabels[i]
            guard let textLabels = tile.textLabels else { continue }
            let count = textLabels.mapLabelCpuMeta.count
            let subArray = Array(labelIntersections[startIndex ..< startIndex + count])
            
            intersectionsResultByTiles[i] = subArray
            startIndex += count
        }
        
        self.geoLabelsWithIntersections = GeoLabelsWithIntersections(
            intersections: intersectionsResultByTiles,
            geoLabels: metalGeoLabels
        )
    }
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if geoLabelsWithIntersections.bufferingCounter <= 0 { return nil }
        
        geoLabelsWithIntersections.bufferingCounter -= 1
        return geoLabelsWithIntersections
    }
    
    func forEvaluateCollisions(
        mapPanning: SIMD3<Double>,
        pipeline: inout ScreenCollisionsDetector.ForEvaluationResult,
        modelMatrices: ModelMatrices
    ) {
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        var metalGeoLabels: [MetalTile.TextLabels] = []
        // Удаляет стухшие тайлы с гео метками
        for geoLabel in self.geoLabels {
            if geoLabel.timePoint == nil || elapsedTime - geoLabel.timePoint! < Settings.labelsFadeAnimationTimeSeconds {
                metalGeoLabels.append(geoLabel)
            }
        }
        self.geoLabels = metalGeoLabels
        //print("geoLabels = ", geoLabels.count)
                
        var inputComputeScreenVertices: [ComputeScreenPositions.Vertex] = []
        var mapLabelLineCollisionsMeta: [MapLabelsAssembler.MapLabelCpuMeta] = []
        for i in 0..<metalGeoLabels.count {
            let metalTile = metalGeoLabels[i]
            let matrixIndex = modelMatrices.getMatrix(tile: metalTile.tile)
            
            guard let textLabels = metalTile.textLabels else { continue }
            let inputArray = textLabels.mapLabelCpuMeta.map {
                label in ComputeScreenPositions.Vertex(location: label.localPosition, matrixId: simd_short1(matrixIndex))
            }
            inputComputeScreenVertices.append(contentsOf: inputArray)
            mapLabelLineCollisionsMeta.append(contentsOf: textLabels.mapLabelCpuMeta)
        }
        
        pipeline.inputComputeScreenVertices = inputComputeScreenVertices
        pipeline.mapLabelLineCollisionsMeta = mapLabelLineCollisionsMeta
        pipeline.metalGeoLabels = metalGeoLabels
        pipeline.geoLabelsSize = inputComputeScreenVertices.count
    }
    
    func setGeoLabels(geoLabels: [MetalTile.TextLabels]) {
        guard geoLabels.isEmpty == false else { return }
        let elapsedTime = frameCounter.getElapsedTimeSeconds()
        
        let currentZ = geoLabels.first!.tile.z
        var savePrevious: [MetalTile.TextLabels] = []
        for i in 0..<self.geoLabels.count {
            var label = self.geoLabels[i]
            let isDifferentZ = label.tile.z != currentZ
            if isDifferentZ {
                label.timePoint = elapsedTime
                savePrevious.append(label)
            }
        }
        
        // ресетит тайлы, делает их снова актуальными
        var geoLabels = geoLabels
        for i in 0..<geoLabels.count {
            geoLabels[i].timePoint = nil
        }
        self.actualLabelsIds = Set(geoLabels.flatMap { label in label.containIds })
        self.geoLabels = geoLabels + savePrevious
    }
}
