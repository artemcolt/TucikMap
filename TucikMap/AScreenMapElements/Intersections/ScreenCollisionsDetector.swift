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
    
    fileprivate let parametersBufferSize        = Settings.geoLabelsParametersBufferSize
    
    fileprivate let computeScreenPositions      : ComputeScreenPositions
    fileprivate let metalDevice                 : MTLDevice
    fileprivate let metalCommandQueue           : MTLCommandQueue
    
    fileprivate let mapZoomState                : MapZoomState
    fileprivate let drawingFrameRequester       : DrawingFrameRequester
    fileprivate let frameCounter                : FrameCounter
    
    fileprivate let handleGeoLabels             : HandleGeoLabels
    fileprivate var handleRoadLabels            : HandleRoadLabels
    
    fileprivate var viewportSize                : SIMD2<Float> = SIMD2<Float>()
    
    
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
        computeScreenPositions: ComputeScreenPositions,
        handleGeoLabels: HandleGeoLabels,
        handleRoadLabels: HandleRoadLabels,
        onPointsReadyHandlerGlobe: OnPointsReadyHandlerGlobe,
        onPointsReadyHandlerFlat: OnPointsReadyHandlerFlat,
    ) {
        self.handleGeoLabels = handleGeoLabels
        self.handleRoadLabels = handleRoadLabels
        
        self.computeScreenPositions = computeScreenPositions
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.drawingFrameRequester = drawingFrameRequester
        self.frameCounter = frameCounter
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
        
        handleRoadLabels.setRoadLabels(roadLabels: roadLabels)
        handleGeoLabels.setGeoLabels(geoLabels: textLabels)
        viewportSize = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
    }
}



class ScreenCollisionsDetectorGlobe : ScreenCollisionsDetector {
    fileprivate var projectPointsGlobe: CombinedCompSPGlobe
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        computeScreenPositions: ComputeScreenPositions,
        handleGeoLabels: HandleGeoLabels,
        handleRoadLabels: HandleRoadLabels,
        onPointsReadyHandlerGlobe: OnPointsReadyHandlerGlobe,
        onPointsReadyHandlerFlat: OnPointsReadyHandlerFlat,
        projectPointsGlobe: CombinedCompSPGlobe
    ) {
        self.projectPointsGlobe = projectPointsGlobe
        super.init(metalDevice: metalDevice,
                   library: library,
                   metalCommandQueue: metalCommandQueue,
                   mapZoomState: mapZoomState,
                   drawingFrameRequester: drawingFrameRequester,
                   frameCounter: frameCounter,
                   computeScreenPositions: computeScreenPositions,
                   handleGeoLabels: handleGeoLabels,
                   handleRoadLabels: handleRoadLabels,
                   onPointsReadyHandlerGlobe: onPointsReadyHandlerGlobe,
                   onPointsReadyHandlerFlat: onPointsReadyHandlerFlat)
    }
    
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
        
        let inputGlobe = CombinedCompSPGlobe.InputGlobe(input: input, parameters: prepareToScreenData.parameters)
        projectPointsGlobe.projectGlobe(inputGlobe: inputGlobe)
        
        return false
    }
}



class ScreenCollisionsDetectorFlat: ScreenCollisionsDetector {
    fileprivate var projectPointsFlat: CombinedCompSPFlat
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        computeScreenPositions: ComputeScreenPositions,
        handleGeoLabels: HandleGeoLabels,
        handleRoadLabels: HandleRoadLabels,
        onPointsReadyHandlerGlobe: OnPointsReadyHandlerGlobe,
        onPointsReadyHandlerFlat: OnPointsReadyHandlerFlat,
        projectPointsFlat: CombinedCompSPFlat
    ) {
        self.projectPointsFlat = projectPointsFlat
        super.init(metalDevice: metalDevice,
                   library: library,
                   metalCommandQueue: metalCommandQueue,
                   mapZoomState: mapZoomState,
                   drawingFrameRequester: drawingFrameRequester,
                   frameCounter: frameCounter,
                   computeScreenPositions: computeScreenPositions,
                   handleGeoLabels: handleGeoLabels,
                   handleRoadLabels: handleRoadLabels,
                   onPointsReadyHandlerGlobe: onPointsReadyHandlerGlobe,
                   onPointsReadyHandlerFlat: onPointsReadyHandlerFlat)
    }
    
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
        let inputFlat = CombinedCompSPFlat.InputFlat(input: input,
                                                     modelMatrices: modelMatricesArray,
                                                     mapPanning: mapPanning,
                                                     mapSize: mapSize,
                                                     viewportSize: viewportSize,
                                                     startRoadResultsIndex: pipeline.startRoadResultsIndex,
                                                     roadLabels: pipeline.metalRoadLabels,
                                                     actualRoadLabelsIds: handleRoadLabels.actualLabelsIds)
        
        projectPointsFlat.projectFlat(inputFlat: inputFlat)
        
        return false
    }
}
