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
    let geoLabels: [MetalTile.TextLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

struct DrawTileRoadLabelsPrep {
    let lineToStartAt: [MapRoadLabelsAssembler.LineToStartAt]
    let startAt: [MapRoadLabelsAssembler.StartRoadAt]
    let labelIntersections: [LabelIntersection]
    let metalRoadLabels: MetalTile.RoadLabels
    let maxInstances: Int
}

// Rendering road labels tripple buffering
struct RenderingRoadLabelsTB {
    let tilesPrepare: [DrawTileRoadLabelsPrep]
    var bufferingCounter: Int
}

class ScreenCollisionsDetector {
    struct ForEvaluationResult {
        var inputComputeScreenVertices: [ComputeScreenPositions.Vertex]
        var mapLabelLineCollisionsMeta: [MapLabelsAssembler.MapLabelCpuMeta]
        var metalGeoLabels: [MetalTile.TextLabels]
        var metalRoadLabels: [MetalTile.RoadLabels]
        var geoLabelsSize: Int
        var startRoadResultsIndex: Int
    }
    
    private let modelMatrixBufferSize       = Settings.geoLabelsModelMatrixBufferSize
    
    private let computeScreenPositions      : ComputeScreenPositions
    private let metalDevice                 : MTLDevice
    private let metalCommandQueue           : MTLCommandQueue
    
    private let mapZoomState                : MapZoomState
    private let drawingFrameRequester       : DrawingFrameRequester
    private let frameCounter                : FrameCounter
    private var projectPoints               : CombinedCompSP!
    
    private let handleGeoLabels             : HandleGeoLabels
    private var handleRoadLabels            : HandleRoadLabels!
    
    private var viewportSize                : SIMD2<Float> = SIMD2<Float>()
    
    
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
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter
    ) {
        handleGeoLabels = HandleGeoLabels(
            frameCounter: frameCounter,
            mapZoomState: mapZoomState,
        )
        
        computeScreenPositions = ComputeScreenPositions(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.drawingFrameRequester = drawingFrameRequester
        self.frameCounter = frameCounter
        self.projectPoints = CombinedCompSP(
            computeScreenPositions: computeScreenPositions,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
        
        handleRoadLabels = HandleRoadLabels(mapZoomState: mapZoomState, frameCounter: frameCounter)
    }
    
    func newState(actualTiles: [MetalTile], view: MTKView) {
        var roadLabels: [MetalTile.RoadLabels] = []
        var textLabels: [MetalTile.TextLabels] = []
        roadLabels.reserveCapacity(actualTiles.count)
        textLabels.reserveCapacity(actualTiles.count)
        for tile in actualTiles {
            roadLabels.append(tile.roads)
            textLabels.append(tile.texts)
        }
        
        self.handleRoadLabels.setRoadLabels(roadLabels: roadLabels)
        self.handleGeoLabels.setGeoLabels(geoLabels: textLabels)
        viewportSize = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
    }
    
    private func onPointsReady(result: CombinedCompSP.Result) {
        //let startTime = CFAbsoluteTimeGetCurrent()
        
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        handleGeoLabels.onPointsReady(result: result, spaceDiscretisation: spaceDiscretisation)
        handleRoadLabels.onPointsReady(result: result, spaceDiscretisation: spaceDiscretisation, viewportSize: viewportSize)
        
        drawingFrameRequester.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
        
        //let endTime = CFAbsoluteTimeGetCurrent()
        //let time = endTime - startTime
        //print(time)
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        var pipeline = ForEvaluationResult(
            inputComputeScreenVertices: [],
            mapLabelLineCollisionsMeta: [],
            metalGeoLabels: [],
            metalRoadLabels: [],
            geoLabelsSize: 0,
            startRoadResultsIndex: 0
        )
        let modelMatrices = ModelMatrices(mapZoomState: mapZoomState, mapPanning: mapPanning)
        
        handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning,
                                              pipeline: &pipeline,
                                              modelMatrices: modelMatrices)
        
        handleRoadLabels.forEvaluateCollisions(mapPanning: mapPanning,
                                               lastUniforms: lastUniforms,
                                               pipeline: &pipeline,
                                               modelMatrices: modelMatrices)
        
        let modelMatricesArray = modelMatrices.getMatricesArray()
        let input = CombinedCompSP.Input(modelMatrices: modelMatricesArray,
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
        
        // TODO
        if modelMatricesArray.count > modelMatrixBufferSize {
            // если быстро зумить камеру туда/cюда то geoLabels будет расти в размере из-за того что анимация не успевает за изменениями
            // в таком случае пропускаем изменения и отображаем старые данные до тех пор пока пользователь не успокоиться
            //renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight) // продолжаем рендрить чтобы обновились данные в конце концов
            return true // recompute is needed again but later
        }
        
        // TODO Как обработать случай когда точек для преобразования слишком много
        if input.inputComputeScreenVertices.count > Settings.maxInputComputeScreenPoints {
            return false // Слишком много точек для преобразования, пропускаем рендринг
        }
        
        projectPoints.project(input: input)
        
        return false
    }
}
