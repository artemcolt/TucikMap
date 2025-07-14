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

struct RoadLabel {
    let name: String
    let localPoints: [SIMD2<Float>]
    let measuredText: MeasuredText
    let scale: Float
}

struct RoadLabels {
    let items: [RoadLabel]
    var draw: MapRoadLabelsAssembler.DrawMapLabelsData?
}

struct RenderingCurrentRoadLabels {
    let draw: MapRoadLabelsAssembler.DrawMapLabelsData
    let lineToStartAt: [MapRoadLabelsAssembler.LineToStartAt]
    let startAt: [MapRoadLabelsAssembler.StartRoadAt]
}

struct RenderingRoads {
    let renderingCurrentRoadLabels: [RenderingCurrentRoadLabels]
    var bufferingCounter: Int
}

class ScreenCollisionsDetector {
    private let computeLabelScreen: ComputeLabelScreen
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private var projectPoints: ProjectPoints!
    let handleGeoLabels: HandleGeoLabels
    
    private var roadLabelsByTiles: [RoadLabels] = []
    
    private var currentRenderingRoads: RenderingRoads = RenderingRoads(renderingCurrentRoadLabels: [], bufferingCounter: 0)
    func getRenderingCurrentRoadLabels() -> RenderingRoads? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if currentRenderingRoads.bufferingCounter <= 0 { return nil }
        
        currentRenderingRoads.bufferingCounter -= 1
        return currentRenderingRoads
    }
    
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        handleGeoLabels = HandleGeoLabels(
            frameCounter: frameCounter,
            mapZoomState: mapZoomState,
            renderFrameCount: renderFrameCount
        )
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
    
    func setRoadLabels(roadLabelsByTiles: [RoadLabels]) {
        self.roadLabelsByTiles = roadLabelsByTiles
    }
    
    private func onPointsReady(result: ProjectPoints.Result) {
        handleGeoLabels.onPointsReady(result: result)
        
        let roadTitleSpacing = Float(100)
        let input = result.input
        let output = result.output
        let nextResultIndex = input.nextResultsIndex
        var roadLabelsByTiles = input.roadLabelsByTiles
        var renderingCurrentRoadLabels: [RenderingCurrentRoadLabels] = []
        for tileRoadLabels in roadLabelsByTiles {
            var lineToStartFloats: [MapRoadLabelsAssembler.LineToStartAt] = []
            var startRoadLabelsAtFull: [MapRoadLabelsAssembler.StartRoadAt] = []
            var maxInstances = 0
//            for roadLabel in tileRoadLabels.items {
//                let measuredText = roadLabel.measuredText
//                let count = roadLabel.localPoints.count
//                var startRoadLabelsAt: [MapRoadLabelsAssembler.StartRoadAt] = []
//                var screenPathLen: Float = 0
//                for i in 0..<count-1 {
//                    let current = output[nextResultIndex + i]
//                    let next = output[nextResultIndex + i + 1]
//                    let len = length(next - current)
//                    screenPathLen += len
//                }
//                let textScreenWidth = measuredText.width * roadLabel.scale
//                let textSpacingWidth = textScreenWidth + roadTitleSpacing
//                let fitCount = Int(screenPathLen / textSpacingWidth)
//                if maxInstances < fitCount { maxInstances = fitCount }
//                for i in 0..<fitCount {
//                    let startFrom = Float(i) * textSpacingWidth
//                    //let factor = startFrom / screenPathLen
//                    startRoadLabelsAt.append(MapRoadLabelsAssembler.StartRoadAt(startAt: startFrom))
//                }
//                lineToStartFloats.append(MapRoadLabelsAssembler.LineToStartAt(
//                    index: simd_int1(startRoadLabelsAtFull.count),
//                    count: simd_int1(startRoadLabelsAt.count)
//                ))
//                startRoadLabelsAtFull.append(contentsOf: startRoadLabelsAt)
//            }
            
            var draw = tileRoadLabels.draw!
            draw.maxInstances = maxInstances
                        
            renderingCurrentRoadLabels.append(RenderingCurrentRoadLabels(
                draw: draw,
                lineToStartAt: lineToStartFloats,
                startAt: startRoadLabelsAtFull
            ))
        }
        
        self.currentRenderingRoads = RenderingRoads(
            renderingCurrentRoadLabels: renderingCurrentRoadLabels,
            bufferingCounter: Settings.maxBuffersInFlight
        )
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        let result = handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning)
        if result.recallLater {
            return true
        }
        
        var forCompute: [InputComputeScreenVertex] = []
        for i in 0..<roadLabelsByTiles.count {
            let roadLabelsOfTile = roadLabelsByTiles[i]
            let tileRoadsLabels = roadLabelsOfTile.items
            for tileRoad in tileRoadsLabels {
                let computeInput = tileRoad.localPoints.map { localPoint in
                    InputComputeScreenVertex(location: localPoint, matrixId: simd_short1(i))
                }
                forCompute.append(contentsOf: computeInput)
            }
        }
        
        var inputComputeScreenVertices = result.inputComputeScreenVertices
        let nextResultsIndex = inputComputeScreenVertices.count
        inputComputeScreenVertices.append(contentsOf: forCompute)
        
        projectPoints.project(input: ProjectPoints.ProjectInput(
            modelMatrices: result.modelMatrices,
            uniforms: lastUniforms,
            inputComputeScreenVertices: inputComputeScreenVertices,
            
            metalGeoLabels: result.metalGeoLabels,
            mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
            actualLabelsIds: handleGeoLabels.actualLabelsIds,
            geoLabelsSize: result.geoLabelsSize,
            
            nextResultsIndex: nextResultsIndex,
            roadLabelsByTiles: roadLabelsByTiles
        ))
        
        return false
    }
}
