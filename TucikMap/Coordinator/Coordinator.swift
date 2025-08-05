//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit

class Coordinator: NSObject, MTKViewDelegate {
    var parent                              : MetalView
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
        
    private var metalTilesStorage           : MetalTilesStorage
    private var renderFrameControl          : RenderFrameControl
    private var drawUI                      : DrawUI!
    private var screenUniforms              : ScreenUniforms!
    private var pipelines                   : Pipelines!
    private var updateBufferedUniform       : UpdateBufferedUniform
    private let mapModeStorage              : MapModeStorage
    private let mapUpdaterStorage           : MapUpdaterStorage
    private let screenCollisionsDetector    : ScreenCollisionsDetector
    private let globeTexturing              : GlobeTexturing
    
    var flatMode: FlatMode
    var globeMode: GlobeMode
    
    init(_ parent: MetalView) {
        self.parent = parent
        
        let device              = MTLCreateSystemDefaultDevice()!
        metalDevice             = device
        metalCommandQueue       = device.makeCommandQueue()!
        semaphore               = DispatchSemaphore(value: Settings.maxBuffersInFlight)
        
        mapZoomState            = MapZoomState()
        screenUniforms          = ScreenUniforms(metalDevice: metalDevice)
        drawPoint               = DrawPoint(metalDevice: metalDevice)
        drawAxes                = DrawAxes(metalDevice: metalDevice)
        drawingFrameRequester   = DrawingFrameRequester()
        frameCounter            = FrameCounter()
        pipelines               = Pipelines(metalDevice: metalDevice)
        mapModeStorage          = MapModeStorage(mapZoomState: mapZoomState)
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
        renderFrameControl      = RenderFrameControl(mapCADisplayLoop: mapCadDisplayLoop,
                                                     drawingFrameRequester: drawingFrameRequester)
        drawUI                  = DrawUI(device: metalDevice, textTools: textTools, screenUniforms: screenUniforms)
        
        updateBufferedUniform   = UpdateBufferedUniform(device: metalDevice,
                                                        mapZoomState: mapZoomState,
                                                        cameraStorage: cameraStorage,
                                                        frameCounter: frameCounter)
        
        screenCollisionsDetector = ScreenCollisionsDetector(metalDevice: metalDevice,
                                                            library: pipelines.library,
                                                            metalCommandQueue: metalCommandQueue,
                                                            mapZoomState: mapZoomState,
                                                            drawingFrameRequester: drawingFrameRequester,
                                                            frameCounter: frameCounter)
        
        globeTexturing          = GlobeTexturing(metalDevide: metalDevice, metalCommandQueue: metalCommandQueue, pipelines: pipelines)
        
        mapUpdaterStorage       = MapUpdaterStorage(mapModeStorage: mapModeStorage,
                                                    mapZoomState: mapZoomState,
                                                    metalDevice: metalDevice,
                                                    camera: cameraStorage,
                                                    textTools: textTools,
                                                    drawingFrameRequester: drawingFrameRequester,
                                                    frameCounter: frameCounter,
                                                    metalTilesStorage: metalTilesStorage,
                                                    mapCadDisplayLoop: mapCadDisplayLoop,
                                                    screenCollisionsDetector: screenCollisionsDetector,
                                                    updateBufferedUniform: updateBufferedUniform,
                                                    globeTexturing: globeTexturing)
        
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
                                           screenCollisionsDetector: screenCollisionsDetector,
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
                                            mapModeStorage: mapModeStorage)
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        cameraStorage.currentView.updateMap(view: view, size: size)
        renderFrameControl.updateView(view: view)
        screenUniforms.update(size: size)
        flatMode.mtkView(view, drawableSizeWillChange: size)
        globeMode.mtkView(view, drawableSizeWillChange: size)
        
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
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            self.semaphore.signal()
            return
        }
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.semaphore.signal()
        }
        
        mapModeStorage.updateTransition()
        mapModeStorage.modeSwitching(view: view)
        if mapModeStorage.switchModeFlag {
            mapModeStorage.switchModeFlag = false
            switch mapModeStorage.mapMode {
            case .flat:
                mapModeStorage.mapMode = .globe
                let halfFlatMapSize = Double(cameraStorage.flatView.mapSize) / 2.0
                let halfGlobeMapSize = Double(cameraStorage.globeView.mapSize) / 2.0
                let flatPanning = cameraStorage.flatView.mapPanning
                let globePanX = flatPanning.x / halfFlatMapSize * halfGlobeMapSize
                let globePanY = flatPanning.y / halfFlatMapSize * halfGlobeMapSize
                //print("globePanX \(globePanX) globePanY \(globePanY)")
                
                cameraStorage.globeView.mapPanning = SIMD3<Double>(globePanX, globePanY, 0)
            case .globe:
                let distortion = Float(abs(cos(cameraStorage.globeView.latitude)))
                cameraStorage.flatView.applyDistortion(distortion: distortion)
                let halfFlatMapSize = Double(cameraStorage.flatView.mapSize) / 2.0
                mapModeStorage.mapMode = .flat
                let globePanning = cameraStorage.globeView.mapPanning
                let flatPanX = globePanning.x * 2.0 * halfFlatMapSize
                let flatPanY = globePanning.y * 2.0 * halfFlatMapSize
                
                cameraStorage.flatView.mapPanning = SIMD3<Double>(flatPanX, flatPanY, 0)
            }
            cameraStorage.currentView.updateMap(view: view, size: view.drawableSize)
        }
        
        updateBufferedUniform.updateUniforms(viewportSize: view.drawableSize)
        
        let uniformsBuffer = updateBufferedUniform.getCurrentFrameBuffer()
        
        if cameraStorage.currentView.isMapStateUpdated() {
            mapUpdaterStorage.currentView.update(view: view, useOnlyCached: false)
        }
        
        switch mapModeStorage.mapMode {
        case .flat:
            flatMode.draw(in: view,
                          renderPassDescriptor: renderPassDescriptor,
                          commandBuffer: commandBuffer)
        case .globe:
            globeMode.draw(in: view,
                           renderPassDescriptor: renderPassDescriptor,
                           commandBuffer: commandBuffer)
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
        
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
}
