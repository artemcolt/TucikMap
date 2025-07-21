//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit
import simd

struct LabelIntersection {
    let hide: Bool
    let createdTime: Float
}

struct GeoLabelsWithIntersections {
    let intersections: [Int: [LabelIntersection]]
    let geoLabels: [MetalGeoLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

struct DrawTileRoadLabelsPrep {
    let lineToStartAt: [MapRoadLabelsAssembler.LineToStartAt]
    let startAt: [MapRoadLabelsAssembler.StartRoadAt]
    let labelIntersections: [LabelIntersection]
    let metalRoadLabels: MetalRoadLabels
    let maxInstances: Int
}

// Rendering road labels tripple buffering
struct RenderingRoadLabelsTB {
    let tilesPrepare: [DrawTileRoadLabelsPrep]
    var bufferingCounter: Int
}

class ScreenCollisionsDetector {
    struct ForEvaluationResult {
        var recallLater: Bool
        var inputComputeScreenVertices: [ComputeScreenPositions.Vertex]
        var mapLabelLineCollisionsMeta: [MapLabelsAssembler.MapLabelCpuMeta]
        var modelMatrices: [matrix_float4x4]
        var metalGeoLabels: [MetalGeoLabels]
        var metalRoadLabels: [MetalRoadLabels]
        var geoLabelsSize: Int
        var startRoadResultsIndex: Int
    }
    
    private let computeScreenPositions: ComputeScreenPositions
    private let metalDevice         : MTLDevice
    private let metalCommandQueue   : MTLCommandQueue
    
    private let mapZoomState        : MapZoomState
    private let renderFrameCount    : RenderFrameCount
    private let frameCounter        : FrameCounter
    private var projectPoints       : CombinedCompSP!
    
    private let handleGeoLabels     : HandleGeoLabels
    private var handleRoadLabels    : HandleRoadLabels!
    
    private var viewportSize        : SIMD2<Float> = SIMD2<Float>()
    
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        return handleGeoLabels.getLabelsWithIntersections()
    }
    
    func getRoadLabels() -> RenderingRoadLabelsTB? {
        return handleRoadLabels.getRoadLabels()
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
        
        computeScreenPositions = ComputeScreenPositions(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.projectPoints = CombinedCompSP(
            computeScreenPositions: computeScreenPositions,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
        
        handleRoadLabels = HandleRoadLabels(mapZoomState: mapZoomState, frameCounter: frameCounter)
    }
    
    func newState(roadLabelsByTiles: [MetalRoadLabels], geoLabels: [MetalGeoLabels], view: MTKView) {
        self.handleRoadLabels.setRoadLabels(roadLabels: roadLabelsByTiles)
        self.handleGeoLabels.setGeoLabels(geoLabels: geoLabels)
        viewportSize = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
    }
    
    private func onPointsReady(result: CombinedCompSP.Result) {
        //let startTime = CFAbsoluteTimeGetCurrent()
        
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        handleGeoLabels.onPointsReady(result: result, spaceDiscretisation: spaceDiscretisation)
        handleRoadLabels.onPointsReady(result: result, spaceDiscretisation: spaceDiscretisation, viewportSize: viewportSize)
        
        //let endTime = CFAbsoluteTimeGetCurrent()
        //let time = endTime - startTime
        //print(time)
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        var pipeline = ForEvaluationResult(
            recallLater: false,
            inputComputeScreenVertices: [],
            mapLabelLineCollisionsMeta: [],
            modelMatrices: [],
            metalGeoLabels: [],
            metalRoadLabels: [],
            geoLabelsSize: 0,
            startRoadResultsIndex: 0
        )
        
        handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning, pipeline: &pipeline)
        if pipeline.recallLater { return true }
        
        handleRoadLabels.forEvaluateCollisions(mapPanning: mapPanning, lastUniforms: lastUniforms, pipeline: &pipeline)
        if pipeline.recallLater { return true }
        
        let input = CombinedCompSP.Input(modelMatrices: pipeline.modelMatrices,
                                         uniforms: lastUniforms,
                                         mapPanning: mapPanning,
                                         inputComputeScreenVertices: pipeline.inputComputeScreenVertices,
                                         
                                         metalGeoLabels: pipeline.metalGeoLabels,
                                         mapLabelLineCollisionsMeta: pipeline.mapLabelLineCollisionsMeta,
                                         actualLabelsIds: handleGeoLabels.actualLabelsIds,
                                         geoLabelsSize: pipeline.geoLabelsSize,
                                         
                                         startRoadResultsIndex: pipeline.startRoadResultsIndex,
                                         roadLabels: pipeline.metalRoadLabels,
                                         actualRoadLabelsIds: handleRoadLabels.actualLabelsIds)
        
        // TODO Как обработать случай когда точек для преобразования слишком много
        if input.inputComputeScreenVertices.count > Settings.maxInputComputeScreenPoints {
            return false // Слишком много точек для преобразования, пропускаем рендринг
        }
        
        projectPoints.project(input: input)
        
        return false
    }
}
