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
    
    fileprivate let parametersBufferSize    = Settings.geoLabelsParametersBufferSize
    
    private let computeScreenPositions      : ComputeScreenPositions
    private let metalDevice                 : MTLDevice
    private let metalCommandQueue           : MTLCommandQueue
    
    fileprivate let mapZoomState            : MapZoomState
    private let drawingFrameRequester       : DrawingFrameRequester
    private let frameCounter                : FrameCounter
    fileprivate var projectPoints           : CombinedCompSP!
    
    fileprivate let handleGeoLabels         : HandleGeoLabels
    fileprivate var handleRoadLabels        : HandleRoadLabels!
    
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
        frameCounter: FrameCounter,
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
            onPointsReadyGlobe: self.onPointsReadyGlobe,
            onPointsReadyFlat: self.onPointsReadyFlat
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
    
    private func onPointsReadyGlobe(resultGlobe: CombinedCompSP.ResultGlobe) {
        let result = resultGlobe.result
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: result.output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceDiscretisation: spaceDiscretisation)
        
        drawingFrameRequester.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
    }
    
    private func onPointsReadyFlat(resultFlat: CombinedCompSP.ResultFlat) {
        let result = resultFlat.result
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: result.output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceDiscretisation: spaceDiscretisation)
        
        let handleRoadInput = HandleRoadLabels.OnPointsReady(output: result.output,
                                                             uniforms: result.uniforms,
                                                             mapPanning: resultFlat.mapPanning,
                                                             mapSize: resultFlat.mapSize,
                                                             startRoadResultsIndex: resultFlat.startRoadResultsIndex,
                                                             metalRoadLabelsTiles: resultFlat.metalRoadLabelsTiles,
                                                             actualRoadLabelsIds: resultFlat.actualRoadLabelsIds)
        
        handleRoadLabels.onPointsReady(result: handleRoadInput, spaceDiscretisation: spaceDiscretisation, viewportSize: viewportSize)
        
        
        drawingFrameRequester.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
    }
}

class ScreenCollisionsDetectorGlobe : ScreenCollisionsDetector {
    func evaluate(lastUniforms: Uniforms,
                  mapPanning: SIMD3<Double>,
                  mapSize: Float,
                  latitude: Float,
                  longitude: Float,
                  globeRadius: Float) -> Bool {
        var pipeline = ForEvaluationResult(
            inputComputeScreenVertices: [],
            mapLabelLineCollisionsMeta: [],
            metalGeoLabels: [],
            metalRoadLabels: [],
            geoLabelsSize: 0,
            startRoadResultsIndex: 0
        )
        
        let prepareToScreenData = PrepareToScreenDataGlobe(mapZoomState: mapZoomState,
                                                          mapPanning: mapPanning,
                                                          latitude: latitude,
                                                          longitude: longitude,
                                                          globeRadius: globeRadius)
        
        
        handleGeoLabels.forEvaluateCollisions(pipeline: &pipeline,
                                              prepareToScreenData: prepareToScreenData)
        
        
        let input = CombinedCompSP.Input(uniforms: lastUniforms,
                                         inputComputeScreenVertices: pipeline.inputComputeScreenVertices,
                                         metalGeoLabels: pipeline.metalGeoLabels,
                                         mapLabelLineCollisionsMeta: pipeline.mapLabelLineCollisionsMeta,
                                         actualLabelsIds: handleGeoLabels.actualLabelsIds,
                                         geoLabelsSize: pipeline.geoLabelsSize)
        
        
        // TODO
        if prepareToScreenData.resultSize > parametersBufferSize {
            // если быстро зумить камеру туда/cюда то geoLabels будет расти в размере из-за того что анимация не успевает за изменениями
            // в таком случае пропускаем изменения и отображаем старые данные до тех пор пока пользователь не успокоиться
            //renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight) // продолжаем рендрить чтобы обновились данные в конце концов
            return true // recompute is needed again but later
        }
        
        // TODO Как обработать случай когда точек для преобразования слишком много
        if input.inputComputeScreenVertices.count > Settings.maxInputComputeScreenPoints {
            return false // Слишком много точек для преобразования, пропускаем рендринг
        }
        
        let inputGlobe = CombinedCompSP.InputGlobe(input: input, parameters: prepareToScreenData.parameters)
        projectPoints.projectGlobe(inputGlobe: inputGlobe)
        
        return false
    }
}

class ScreenCollisionsDetectorFlat : ScreenCollisionsDetector {
    func evaluate(lastUniforms: Uniforms,
                  mapPanning: SIMD3<Double>,
                  mapSize: Float) -> Bool {
        var pipeline = ForEvaluationResult(
            inputComputeScreenVertices: [],
            mapLabelLineCollisionsMeta: [],
            metalGeoLabels: [],
            metalRoadLabels: [],
            geoLabelsSize: 0,
            startRoadResultsIndex: 0
        )
        
        let prepareToScreenData = PrepareToScreenDataFlat(mapZoomState: mapZoomState, mapPanning: mapPanning, mapSize: mapSize)
        
        
        handleGeoLabels.forEvaluateCollisions(pipeline: &pipeline,
                                              prepareToScreenData: prepareToScreenData)
        
        handleRoadLabels.forEvaluateCollisions(pipeline: &pipeline,
                                               prepareToScreenData: prepareToScreenData)
        
        let input = CombinedCompSP.Input(uniforms: lastUniforms,
                                         inputComputeScreenVertices: pipeline.inputComputeScreenVertices,
                                         metalGeoLabels: pipeline.metalGeoLabels,
                                         mapLabelLineCollisionsMeta: pipeline.mapLabelLineCollisionsMeta,
                                         actualLabelsIds: handleGeoLabels.actualLabelsIds,
                                         geoLabelsSize: pipeline.geoLabelsSize)
        
        
        // TODO
        if prepareToScreenData.resultSize > parametersBufferSize {
            // если быстро зумить камеру туда/cюда то geoLabels будет расти в размере из-за того что анимация не успевает за изменениями
            // в таком случае пропускаем изменения и отображаем старые данные до тех пор пока пользователь не успокоиться
            //renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight) // продолжаем рендрить чтобы обновились данные в конце концов
            return true // recompute is needed again but later
        }
        
        // TODO Как обработать случай когда точек для преобразования слишком много
        if input.inputComputeScreenVertices.count > Settings.maxInputComputeScreenPoints {
            return false // Слишком много точек для преобразования, пропускаем рендринг
        }
        
        let modelMatricesArray = prepareToScreenData.matrices
        let inputFlat = CombinedCompSP.InputFlat(input: input,
                                                 modelMatrices: modelMatricesArray,
                                                 mapPanning: mapPanning,
                                                 mapSize: mapSize,
                                                 startRoadResultsIndex: pipeline.startRoadResultsIndex,
                                                 roadLabels: pipeline.metalRoadLabels,
                                                 actualRoadLabelsIds: handleRoadLabels.actualLabelsIds)
        
        projectPoints.projectFlat(inputFlat: inputFlat)
        
        return false
    }
}
