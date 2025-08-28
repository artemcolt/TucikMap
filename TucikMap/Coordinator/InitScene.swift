//
//  InitScene.swift
//  TucikMap
//
//  Created by Artem on 8/28/25.
//

import MetalKit

class InitScene {
    let cameraStorage                       : CameraStorage
    let mapController                       : MapController
    let cameraInputsHandler                 : CameraInputsHandler
    
    let metalDevice                 : MTLDevice
    let metalCommandQueue           : MTLCommandQueue
    let semaphore                   : DispatchSemaphore
    
    let mapSettings                 : MapSettings
    let determineFeatureStyle       : DetermineFeatureStyle
    let frameCounter                : FrameCounter
    let drawingFrameRequester       : DrawingFrameRequester
    let textTools                   : TextTools
    let mapCadDisplayLoop           : MapCADisplayLoop
    let mapZoomState                : MapZoomState
    let drawPoint                   : DrawPoint
    let drawSpace                   : DrawSpace
    let drawGlobeGlowing            : DrawGlobeGlowing
    let drawTextureOnScreen         : DrawTextureOnScreen
    let textureAdder                : TextureAdder
    let renderPassWrapper           : RenderPassWrapper
    
    let metalTilesStorage           : MetalTilesStorage
    let renderFrameControl          : RenderFrameControl
    let drawUI                      : DrawUI
    let drawDebugData               : DrawDebugData
    let screenUniforms              : ScreenUniforms
    let pipelines                   : Pipelines
    let updateBufferedUniform       : UpdateBufferedUniform
    let mapModeStorage              : MapModeStorage
    let mapUpdaterStorage           : MapUpdaterStorage
    let globeTexturing              : GlobeTexturing
    let switchMapMode               : SwitchMapMode
    let applyLabelsState            : ApplyLabelsState
    let scrCollDetStorage           : ScrCollDetStorage
    let textureLoader               : TextureLoader
    let markersStorage              : MarkersStorage
    
    let flatMode                    : FlatMode
    let globeMode                   : GlobeMode
    
    init(mapSettings: MapSettings) {
        self.mapSettings        = mapSettings
        
        let device              = MTLCreateSystemDefaultDevice()!
        metalDevice             = device
        metalCommandQueue       = device.makeCommandQueue()!
        semaphore               = DispatchSemaphore(value: mapSettings.getMapCommonSettings().getMaxBuffersInFlight())
        
        mapZoomState            = MapZoomState()
        screenUniforms          = ScreenUniforms(metalDevice: metalDevice)
        drawPoint               = DrawPoint(metalDevice: metalDevice)
        drawSpace               = DrawSpace(metalDevice: metalDevice)
        drawGlobeGlowing        = DrawGlobeGlowing(metalDevice: metalDevice)
        drawingFrameRequester   = DrawingFrameRequester(mapSettings: mapSettings)
        frameCounter            = FrameCounter()
        pipelines               = Pipelines(metalDevice: metalDevice)
        textureAdder            = TextureAdder(metalDevice: metalDevice, textureAdderPipeline: pipelines.textureAdderPipeline)
        drawTextureOnScreen     = DrawTextureOnScreen(metalDevice: metalDevice, postProcessingPipeline: pipelines.postProcessing)
        mapModeStorage          = MapModeStorage()
        textureLoader           = TextureLoader(metalDevice: metalDevice)
        mapCadDisplayLoop       = MapCADisplayLoop(frameCounter: frameCounter,
                                                   drawingFrameRequester: drawingFrameRequester,
                                                   mapSettings: mapSettings)
        cameraStorage           = CameraStorage(mapModeStorage: mapModeStorage,
                                                mapZoomState: mapZoomState,
                                                drawingFrameRequester: drawingFrameRequester,
                                                mapCadDisplayLoop: mapCadDisplayLoop,
                                                mapSettings: mapSettings)
        mapController           = MapController(drawingFrameRequester: drawingFrameRequester, cameraStorage: cameraStorage)
        cameraInputsHandler     = CameraInputsHandler(mapController: mapController, cameraStorage: cameraStorage, mapSettings: mapSettings)
        
        determineFeatureStyle   = DetermineFeatureStyle(mapSettings: mapSettings)
        textTools               = TextTools(metalDevice: metalDevice, frameCounter: frameCounter, mapSettings: mapSettings)
        metalTilesStorage       = MetalTilesStorage(determineStyle: determineFeatureStyle,
                                                    metalDevice: metalDevice,
                                                    textTools: textTools,
                                                    mapSettings: mapSettings)
        switchMapMode           = SwitchMapMode(mapModeStorage: mapModeStorage,
                                                cameraStorage: cameraStorage,
                                                mapZoomState: mapZoomState,
                                                mapSettings: mapSettings,
                                                mapController: mapController)
        renderFrameControl      = RenderFrameControl(mapCADisplayLoop: mapCadDisplayLoop,
                                                     drawingFrameRequester: drawingFrameRequester,
                                                     mapSettings: mapSettings)
        drawUI                  = DrawUI(device: metalDevice, textTools: textTools, screenUniforms: screenUniforms)
        renderPassWrapper       = RenderPassWrapper(metalDevice: metalDevice)
        drawDebugData           = DrawDebugData(metalDevice: metalDevice,
                                                cameraStorage: cameraStorage,
                                                textPipeline: pipelines.textPipeline,
                                                drawUI: drawUI,
                                                drawPoint: drawPoint,
                                                mapZoomState: mapZoomState,
                                                mapSettings: mapSettings)
        
        updateBufferedUniform   = UpdateBufferedUniform(device: metalDevice,
                                                        mapZoomState: mapZoomState,
                                                        cameraStorage: cameraStorage,
                                                        frameCounter: frameCounter,
                                                        mapSettings: mapSettings)
        
        scrCollDetStorage       = ScrCollDetStorage(mapModeStorage: mapModeStorage,
                                                    metalDevice: metalDevice,
                                                    library: pipelines.library,
                                                    metalCommandQueue: metalCommandQueue,
                                                    mapZoomState: mapZoomState,
                                                    drawingFrameRequester: drawingFrameRequester,
                                                    frameCounter: frameCounter,
                                                    mapSettings: mapSettings)
        
        
        globeTexturing          = GlobeTexturing(metalDevice: metalDevice,
                                                 metalCommandQueue: metalCommandQueue,
                                                 pipelines: pipelines,
                                                 mapSettings: mapSettings)
        
        let mapUpdaterContext   = MapUpdaterContext()
        mapUpdaterStorage       = MapUpdaterStorage(mapModeStorage: mapModeStorage,
                                                    mapZoomState: mapZoomState,
                                                    metalDevice: metalDevice,
                                                    camera: cameraStorage,
                                                    textTools: textTools,
                                                    drawingFrameRequester: drawingFrameRequester,
                                                    frameCounter: frameCounter,
                                                    metalTilesStorage: metalTilesStorage,
                                                    mapCadDisplayLoop: mapCadDisplayLoop,
                                                    scrCollDetStorage: scrCollDetStorage,
                                                    updateBufferedUniform: updateBufferedUniform,
                                                    globeTexturing: globeTexturing,
                                                    mapUpdaterContext: mapUpdaterContext,
                                                    mapSettings: mapSettings)
        
        applyLabelsState        = ApplyLabelsState(scrCollDetStorage: scrCollDetStorage,
                                                   assembledMap: mapUpdaterContext.assembledMap)
        
        markersStorage          = MarkersStorage(metalDevice: metalDevice,
                                                 mapSettings: mapSettings,
                                                 cameraStorage: cameraStorage)
        
        flatMode                = FlatMode(metalDevice: metalDevice,
                                           metalCommandQueue: metalCommandQueue,
                                           frameCounter: frameCounter,
                                           drawingFrameRequester: drawingFrameRequester,
                                           textTools: textTools,
                                           metalTilesStorage: metalTilesStorage,
                                           mapCadDisplayLoop: mapCadDisplayLoop,
                                           screenUniforms: screenUniforms,
                                           cameraStorage: cameraStorage,
                                           pipelines: pipelines,
                                           mapZoomState: mapZoomState,
                                           updateBufferedUniform: updateBufferedUniform,
                                           mapModeStorage: mapModeStorage,
                                           drawPoint: drawPoint,
                                           mapUpdaterFlat: mapUpdaterStorage.flat,
                                           mapSettings: mapSettings,
                                           textureLoader: textureLoader,
                                           markersStorage: markersStorage)
        
        globeMode               = GlobeMode(metalDevice: metalDevice,
                                            pipelines: pipelines,
                                            metalTilesStorage: metalTilesStorage,
                                            cameraStorage: cameraStorage,
                                            mapZoomState: mapZoomState,
                                            drawingFrameRequester: drawingFrameRequester,
                                            mapCadDisplayLoop: mapCadDisplayLoop,
                                            updateBufferedUniform: updateBufferedUniform,
                                            globeTexturing: globeTexturing,
                                            screenUniforms: screenUniforms,
                                            mapUpdater: mapUpdaterStorage.globe,
                                            switchMapMode: switchMapMode,
                                            drawSpace: drawSpace,
                                            drawGlobeGlowing: drawGlobeGlowing,
                                            textureAdder: textureAdder,
                                            mapSettings: mapSettings,
                                            textureLoader: textureLoader,
                                            markersStorage: markersStorage,
                                            drawDebugData: drawDebugData,
                                            drawUI: drawUI)
        
        if let controllerCreated = mapSettings.getMapCommonSettings().getControllerCreated() {
            controllerCreated.onControllerReady(mapController: mapController)
        }
    }
}
