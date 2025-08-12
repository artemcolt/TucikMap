//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit
import MetalPerformanceShaders

class Coordinator: NSObject, MTKViewDelegate {
    var parent                              : TucikMapView
    var cameraStorage                       : CameraStorage
    
    private var metalDevice                 : MTLDevice
    private var metalCommandQueue           : MTLCommandQueue
    private var semaphore                   : DispatchSemaphore
    
    private var determineFeatureStyle       : DetermineFeatureStyle
    private var frameCounter                : FrameCounter
    private var drawingFrameRequester       : DrawingFrameRequester!
    private var textTools                   : TextTools
    private var mapCadDisplayLoop           : MapCADisplayLoop
    private var mapZoomState                : MapZoomState
    private var drawPoint                   : DrawPoint
    private var drawAxes                    : DrawAxes
    private let drawSpace                   : DrawSpace
    private let drawGlobeGlowing            : DrawGlobeGlowing
    private let drawTextureOnScreen         : DrawTextureOnScreen
    private let textureAdder                : TextureAdder
    private let renderPassWrapper           : RenderPassWrapper
    
    private var metalTilesStorage           : MetalTilesStorage
    private var renderFrameControl          : RenderFrameControl
    private var drawUI                      : DrawUI!
    private var screenUniforms              : ScreenUniforms!
    private var pipelines                   : Pipelines!
    private var updateBufferedUniform       : UpdateBufferedUniform
    private let mapModeStorage              : MapModeStorage
    private let mapUpdaterStorage           : MapUpdaterStorage
    private let globeTexturing              : GlobeTexturing
    private let switchMapMode               : SwitchMapMode
    private let applyLabelsState            : ApplyLabelsState
    private let scrCollDetStorage           : ScrCollDetStorage
    
    var flatMode: FlatMode
    var globeMode: GlobeMode
    
    init(_ parent: TucikMapView) {
        self.parent = parent
        
        let device              = MTLCreateSystemDefaultDevice()!
        metalDevice             = device
        metalCommandQueue       = device.makeCommandQueue()!
        semaphore               = DispatchSemaphore(value: Settings.maxBuffersInFlight)

        mapZoomState            = MapZoomState()
        screenUniforms          = ScreenUniforms(metalDevice: metalDevice)
        drawPoint               = DrawPoint(metalDevice: metalDevice)
        drawAxes                = DrawAxes(metalDevice: metalDevice)
        drawSpace               = DrawSpace(metalDevice: metalDevice)
        drawGlobeGlowing        = DrawGlobeGlowing(metalDevice: metalDevice)
        drawingFrameRequester   = DrawingFrameRequester()
        frameCounter            = FrameCounter()
        pipelines               = Pipelines(metalDevice: metalDevice)
        textureAdder            = TextureAdder(metalDevice: metalDevice, textureAdderPipeline: pipelines.textureAdderPipeline)
        drawTextureOnScreen     = DrawTextureOnScreen(metalDevice: metalDevice, postProcessingPipeline: pipelines.postProcessing)
        mapModeStorage          = MapModeStorage()
        mapCadDisplayLoop       = MapCADisplayLoop(frameCounter: frameCounter,
                                                   drawingFrameRequester: drawingFrameRequester)
        cameraStorage           = CameraStorage(mapModeStorage: mapModeStorage,
                                                mapZoomState: mapZoomState,
                                                drawingFrameRequester: drawingFrameRequester,
                                                mapCadDisplayLoop: mapCadDisplayLoop)
        determineFeatureStyle   = DetermineFeatureStyle()
        textTools               = TextTools(metalDevice: metalDevice, frameCounter: frameCounter)
        metalTilesStorage       = MetalTilesStorage(determineStyle: determineFeatureStyle,
                                                    metalDevice: metalDevice,
                                                    textTools: textTools)
        switchMapMode           = SwitchMapMode(mapModeStorage: mapModeStorage, cameraStorage: cameraStorage, mapZoomState: mapZoomState)
        renderFrameControl      = RenderFrameControl(mapCADisplayLoop: mapCadDisplayLoop,
                                                     drawingFrameRequester: drawingFrameRequester)
        drawUI                  = DrawUI(device: metalDevice, textTools: textTools, screenUniforms: screenUniforms)
        renderPassWrapper       = RenderPassWrapper(metalDevice: metalDevice)
        
        updateBufferedUniform   = UpdateBufferedUniform(device: metalDevice,
                                                        mapZoomState: mapZoomState,
                                                        cameraStorage: cameraStorage,
                                                        frameCounter: frameCounter)
        
        scrCollDetStorage       = ScrCollDetStorage(mapModeStorage: mapModeStorage,
                                                    metalDevice: metalDevice,
                                                    library: pipelines.library,
                                                    metalCommandQueue: metalCommandQueue,
                                                    mapZoomState: mapZoomState,
                                                    drawingFrameRequester: drawingFrameRequester,
                                                    frameCounter: frameCounter)
        
        
        globeTexturing          = GlobeTexturing(metalDevide: metalDevice, metalCommandQueue: metalCommandQueue, pipelines: pipelines)
        
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
                                                    mapUpdaterContext: mapUpdaterContext)
        
        applyLabelsState        = ApplyLabelsState(scrCollDetStorage: scrCollDetStorage,
                                                   assembledMap: mapUpdaterContext.assembledMap)
        
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
                                           mapUpdaterFlat: mapUpdaterStorage.flat)
        
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
                                            textureAdder: textureAdder)
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderPassWrapper.mtkView(view: view, drawableSizeWillChange: size)
        
        cameraStorage.currentView.updateMap(view: view, size: size)
        renderFrameControl.updateView(view: view)
        screenUniforms.update(size: size)
        flatMode.mtkView(view, drawableSizeWillChange: size)
        
        if Settings.useGoToAtStart {
            let camera = cameraStorage.currentView
            let goToLocationAtStart = Settings.goToLocationAtStart
            let zoom = Settings.goToAtStartZ
            camera.moveTo(lat: goToLocationAtStart.x, lon: goToLocationAtStart.y, zoom: zoom, view: view, size: size)
        }
    }
    
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor?.copy() as? MTLRenderPassDescriptor else {
            self.semaphore.signal()
            return
        }
        
        renderPassWrapper.startFrame(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.semaphore.signal()
        }
        
        // Поменять режим рендринга когда нужно
        // Глобус / Плоскость
        let switched = switchMapMode.switchingMapMode(view: view)
        renderPassWrapper.updateClearColor(switchMapMode: switchMapMode)
        
        // Юниформ для трансформации сцены в clip
        updateBufferedUniform.updateUniforms(viewportSize: view.drawableSize)
        
        let uniformsBuffer = updateBufferedUniform.getCurrentFrameBuffer()
        let currentFBIdx = updateBufferedUniform.getCurrentFrameBufferIndex()
        let lastUniforms = updateBufferedUniform.lastUniforms!
        let camera = cameraStorage.currentView
        let mapPanning = camera.mapPanning
        let mapSize = camera.mapSize
        
        // Если камера поменяла состояние то нужно обновить саму карту, тайлы
        if cameraStorage.currentView.isMapStateUpdated() || switched {
            mapUpdaterStorage.currentView.update(view: view, useOnlyCached: false)
        }
        
        // Расчет экранной UI информации, пересечения текста например
        if (mapCadDisplayLoop.checkEvaluateScreenData()) {
            switch mapModeStorage.mapMode {
            case .flat: let _ = scrCollDetStorage.flat.evaluateFlat(lastUniforms: lastUniforms,
                                                                    mapPanning: mapPanning,
                                                                    mapSize: mapSize)
            case .globe: let _ = scrCollDetStorage.globe.evaluateGlobe(lastUniforms: lastUniforms,
                                                                       latitude: camera.latitude,
                                                                       longitude: camera.longitude,
                                                                       globeRadius: camera.globeRadius,
                                                                       cameraPosition: camera.cameraPosition)
            }
        }
        
        // Применяем если есть актуальные данные меток для свежего кадра
        applyLabelsState.apply(currentFBIdx: currentFBIdx)
        
        switch mapModeStorage.mapMode {
        case .flat:
            flatMode.draw(in: view, renderPassWrapper: renderPassWrapper)
        case .globe:
            globeMode.draw(in: view, renderPassWrapper: renderPassWrapper)
        }
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.texture = nil
        renderPassDescriptor.stencilAttachment.texture = nil
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.basePipeline.selectPipeline(renderEncoder: renderEncoder)
        drawPoint.draw(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: Settings.cameraCenterPointSize,
            position: cameraStorage.currentView.targetPosition,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        drawAxes.draw(renderEncoder: renderEncoder,
                      uniformsBuffer: uniformsBuffer,
                      lineLength: 1.0,
                      position: SIMD3<Float>(0, 0, 0)
        )
        
        pipelines.textPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawUI.drawZoomUiText(renderCommandEncoder: renderEncoder, size: view.drawableSize, mapZoomState: mapZoomState)
        renderEncoder.endEncoding()
        
        
        drawTextureOnScreen.draw(currentRenderPassDescriptor: view.currentRenderPassDescriptor,
                                 commandBuffer: commandBuffer,
                                 sceneTexture: renderPassWrapper.getScreenTexture())
        
        
        
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
}
