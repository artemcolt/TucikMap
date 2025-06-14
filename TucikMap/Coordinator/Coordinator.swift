//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import SwiftUI
import MetalKit

class Coordinator: NSObject, MTKViewDelegate {
    var parent: MetalView!
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let controlsDelegate: ControlsDelegate!
    var renderFrameControl: RenderFrameControl!
    var mapCADisplayLoop: MapCADisplayLoop!
    var renderFrameCount: RenderFrameCount!
    
    var depthStencilState: MTLDepthStencilState!
    var frameCounter: FrameCounter!
    
    // Helpers
    var drawTestCube: DrawTestCube!
    var drawAxis: DrawAxis!
    var drawGrid: DrawGrid!
    var drawPoint: DrawPoint!
    
    // Tile
    var assembledMapWrapper: DrawAssembledMap!
    
    // Text
    var textTools: TextTools!
    
    // Map
    var mapZoomState: MapZoomState!
    var camera: Camera!
    var mapLabelsIntersection: MapLabelsIntersection!
    
    // UI
    var drawUI: DrawUI!
    var screenUniforms: ScreenUniforms!
    
    // Pipelines
    var pipelines: Pipelines!
    
    // Accumulated translation for panning
    var translationPosition: SIMD2<Float> = SIMD2<Float>(0, 0)
    
    
    init(_ parent: MetalView) {
        self.parent = parent
        self.controlsDelegate = ControlsDelegate()
        self.renderFrameCount = RenderFrameCount()
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
            pipelines = Pipelines(metalDevice: device)
            drawTestCube = DrawTestCube(metalDevice: device)
            drawAxis = DrawAxis(metalDevice: device, mapState: mapZoomState)
            drawGrid = DrawGrid(metalDevice: device, mapZoomState: mapZoomState)
            drawPoint = DrawPoint(metalDevice: device)
            textTools = TextTools(metalDevice: metalDevice)
            screenUniforms = ScreenUniforms(metalDevice: device)
            camera = Camera(
                mapZoomState: mapZoomState,
                device: device,
                textTools: textTools,
                renderFrameCount: renderFrameCount
            )
            mapLabelsIntersection = MapLabelsIntersection(
                metalDevice: metalDevice,
                metalCommandQueue: metalCommandQueue,
                transformWorldToScreenPositionPipeline: pipelines.transformToScreenPipeline,
                assembledMap: camera.assembledMapUpdater.assembledMap,
                renderFrameCount: renderFrameCount
            )
            assembledMapWrapper = DrawAssembledMap(
                metalDevice: metalDevice,
                screenUniforms: screenUniforms,
            )
            drawUI = DrawUI(device: device, textTools: textTools, mapZoomState: mapZoomState, screenUniforms: screenUniforms)
            mapCADisplayLoop = MapCADisplayLoop(
                mapLablesIntersection: mapLabelsIntersection,
                updateBufferedUniform: camera.updateBufferedUniform,
                needComputeMapLabelsIntersections: camera.assembledMapUpdater.needComputeLabelsIntersections
            )
            self.renderFrameControl = RenderFrameControl(mapCADisplayLoop: mapCADisplayLoop, renderFrameCount: renderFrameCount)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderFrameControl.updateView(view: view)
        
        // Handle viewport size changes - update all uniform buffers
        screenUniforms.update(size: size)
        camera.updateMap(view: view, size: size)
        //camera.moveToTile(tileX: 18, tileY: 10, tileZ: 5, view: view, size: size)
        
    }
    
    // Three-step rendering process
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = camera.updateBufferedUniform!.semaphore.wait(timeout: .distantFuture)
        
        camera.updateBufferedUniform!.updateUniforms(viewportSize: view.drawableSize)
        let uniformsBuffer = camera.updateBufferedUniform.getCurrentFrameBuffer()
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            renderComplete()
            return
        }
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.renderComplete()
        }
        
        pipelines.polygonPipeline.selectPipeline(renderEncoder: renderEncoder)
        assembledMapWrapper.drawTiles(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: camera.assembledMapUpdater.assembledMap.tiles
        )
        
        pipelines.labelsPipeline.selectPipeline(renderEncoder: renderEncoder)
        assembledMapWrapper.drawMapLabels(
            renderEncoder: renderEncoder,
            uniforms: uniformsBuffer,
            drawLabelsData: camera.assembledMapUpdater.assembledMap.labelsAssembled?.drawMapLabelsData
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
            position: camera.targetPosition,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        drawAxis.draw(renderEncoder: renderEncoder, uniformsBuffer: uniformsBuffer)
        
        
        pipelines.textPipeline.selectPipeline(renderEncoder: renderEncoder)
        if let text = camera.assembledMapUpdater?.assembledTileTitles {
            textTools.drawText.renderText(renderEncoder: renderEncoder, uniforms: uniformsBuffer, drawTextData: text)
        }
        drawUI.drawZoomUiText(renderCommandEncoder: renderEncoder, size: view.drawableSize)
        
        
        renderEncoder.endEncoding()
        // Present the drawable to the screen
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
    
    private func renderComplete() {
        camera.updateBufferedUniform!.semaphore.signal()
    }
}
