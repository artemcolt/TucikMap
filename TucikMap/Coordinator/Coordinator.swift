//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import SwiftUI
import MetalKit

class Coordinator: NSObject, MTKViewDelegate {
    var parent: MetalView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let controlsDelegate: ControlsDelegate!
    
    var depthStencilState: MTLDepthStencilState!
    var frameCounter: FrameCounter!
    
    // Helpers
    var drawTestCube: DrawTestCube!
    var drawAxis: DrawAxis!
    var drawGrid: DrawGrid!
    var drawPoint: DrawPoint!
    
    // Tile
    var drawAssembledMap: DrawAssembledMap!
    
    // Text
    var textTools: TextTools!
    var drawMapLabels: DrawMapLabels!
    
    // Map
    var mapZoomState: MapZoomState!
    var camera: Camera!
    
    // UI
    var drawUI: DrawUI!
    
    // Pipelines
    var pipelines: Pipelines!
    
    // Accumulated translation for panning
    var translationPosition: SIMD2<Float> = SIMD2<Float>(0, 0)
    
    
    init(_ parent: MetalView) {
        self.parent = parent
        self.controlsDelegate = ControlsDelegate()
        super.init()
        
        if let device = MTLCreateSystemDefaultDevice() {
            self.metalDevice = device
            self.metalCommandQueue = device.makeCommandQueue()
            
            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .less
            depthStencilDescriptor.isDepthWriteEnabled = true
            depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            
            frameCounter = FrameCounter()
            mapZoomState = MapZoomState()
            drawTestCube = DrawTestCube(metalDevice: device)
            drawAxis = DrawAxis(metalDevice: device, mapState: mapZoomState)
            drawGrid = DrawGrid(metalDevice: device, mapZoomState: mapZoomState)
            drawPoint = DrawPoint(metalDevice: device)
            textTools = TextTools(metalDevice: metalDevice)
            drawAssembledMap = DrawAssembledMap(metalDevice: metalDevice)
            pipelines = Pipelines(metalDevice: device)
            drawUI = DrawUI(device: device, textTools: textTools, mapZoomState: mapZoomState)
            camera = Camera(mapZoomState: mapZoomState, device: device, textTools: textTools)
            drawMapLabels = DrawMapLabels(textTools: textTools)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle viewport size changes - update all uniform buffers
        drawUI.updateSize(size: size)
        camera.updateMap(view: view, size: size)
        
        camera.moveToTile(tileX: 18, tileY: 10, tileZ: 5, view: view, size: size)
    }
    
    // Three-step rendering process
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = camera.updateBufferedUnifrom!.semaphore.wait(timeout: .distantFuture)
        
        drawAssembledMap.setCurrentAssembledMap(assembledMap: camera.assembledMapUpdater?.assembledMap)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            renderComplete()
            return
        }
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.renderComplete()
        }
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            renderComplete()
            return
        }
        
        let uniformsBuffer = camera.updateBufferedUnifrom!.getCurrentFrameBuffer()
        
        pipelines.polygonPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawAssembledMap.drawAssembledMap(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer
        )
        
        pipelines.basePipeline.selectPipeline(renderEncoder: renderEncoder)
        drawGrid.draw(renderEncoder: renderEncoder,
                      uniformsBuffer: uniformsBuffer,
                      camTileX: Int(camera.centerTileX),
                      camTileY: Int(camera.centerTileY),
                      gridThickness: Settings.gridThickness * mapZoomState.mapScaleFactor,
        )
        drawPoint.draw(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: Settings.cameraCenterPointSize * mapZoomState.mapScaleFactor,
            position: camera.targetPosition
        )
        drawAxis.draw(renderEncoder: renderEncoder, uniformsBuffer: uniformsBuffer)
        
        pipelines.textPipeline.selectPipeline(renderEncoder: renderEncoder)
        //drawMapLabels.draw(renderEncoder: renderEncoder, uniforms: uniformsBuffer)
        if let text = camera.assembledMapUpdater?.assembledTileTitles {
            textTools.drawText.renderText(renderEncoder: renderEncoder, uniforms: uniformsBuffer, drawTextData: text)
        }
        drawUI.drawZoomUiText(renderCommandEncoder: renderEncoder)
        
        
        renderEncoder.endEncoding()
        // Present the drawable to the screen
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
    
    private func renderComplete() {
        camera.updateBufferedUnifrom!.semaphore.signal()
    }
}
