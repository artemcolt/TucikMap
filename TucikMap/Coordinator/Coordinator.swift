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
    var renderFrameCount: RenderFrameCount!
    
    var depthStencilState: MTLDepthStencilState!
    var defaultDepthStencilState: MTLDepthStencilState!
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
    
    // UI
    var drawUI: DrawUI!
    var screenUniforms: ScreenUniforms!
    var screenCollisionsDetector: ScreenCollisionsDetector!
    
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
            
            // Настройка stencil-теста
            let stencilDescriptor = MTLStencilDescriptor()
            stencilDescriptor.stencilCompareFunction = .equal
            stencilDescriptor.stencilFailureOperation = .keep
            stencilDescriptor.depthFailureOperation = .keep
            stencilDescriptor.depthStencilPassOperation = .incrementClamp // Увеличиваем stencil при рендеринге
            stencilDescriptor.readMask = 0xFF
            stencilDescriptor.writeMask = 0xFF
            
            depthStencilDescriptor.frontFaceStencil = stencilDescriptor
            depthStencilDescriptor.backFaceStencil = stencilDescriptor
            depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            
            
            let defaultDepthStencilDescriptor = MTLDepthStencilDescriptor()
            defaultDepthStencilDescriptor.depthCompareFunction = .always
            defaultDepthStencilState = device.makeDepthStencilState(descriptor: defaultDepthStencilDescriptor)
            
            frameCounter = FrameCounter()
            mapZoomState = MapZoomState()
            pipelines = Pipelines(metalDevice: device)
            drawTestCube = DrawTestCube(metalDevice: device)
            drawAxis = DrawAxis(metalDevice: device, mapState: mapZoomState)
            drawGrid = DrawGrid(metalDevice: device, mapZoomState: mapZoomState)
            drawPoint = DrawPoint(metalDevice: device)
            textTools = TextTools(metalDevice: metalDevice, frameCounter: frameCounter)
            screenUniforms = ScreenUniforms(metalDevice: device)
            screenCollisionsDetector = ScreenCollisionsDetector(
                metalDevice: device,
                library: pipelines.library,
                metalCommandQueue: metalCommandQueue,
                mapZoomState: mapZoomState,
                renderFrameCount: renderFrameCount,
                frameCounter: frameCounter
            )
            camera = Camera(
                mapZoomState: mapZoomState,
                device: device,
                textTools: textTools,
                renderFrameCount: renderFrameCount,
                frameCounter: frameCounter,
                library: pipelines.library,
                metalCommandQueue: metalCommandQueue,
                screenCollisionsDetector: screenCollisionsDetector
            )
            assembledMapWrapper = DrawAssembledMap(
                metalDevice: metalDevice,
                screenUniforms: screenUniforms,
                camera: camera,
                mapZoomState: mapZoomState
            )
            drawUI = DrawUI(device: device, textTools: textTools, mapZoomState: mapZoomState, screenUniforms: screenUniforms)
            self.renderFrameControl = RenderFrameControl(mapCADisplayLoop: camera.mapCadDisplayLoop, renderFrameCount: renderFrameCount)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderFrameControl.updateView(view: view)
        
        // Handle viewport size changes - update all uniform buffers
        screenUniforms.update(size: size)
        camera.updateMap(view: view, size: size)
        
        //camera.moveTo(lat: 55.75223153538435, lon: 37.62591025630741, zoom: 16, view: view, size: size)
    }
    
    // Three-step rendering process
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = camera.updateBufferedUniform!.semaphore.wait(timeout: .distantFuture)
        
        camera.updateBufferedUniform!.updateUniforms(viewportSize: view.drawableSize)
        let currentFBIdx = camera.updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer = camera.updateBufferedUniform.getCurrentFrameBuffer()
        let assembledMap = camera.assembledMapUpdater.assembledMap
        let assembledTiles = assembledMap.tiles
        let mapPanning = camera.mapPanning
        var modelMatrices: [matrix_float4x4] = []
        for tile in assembledTiles {
            let modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            modelMatrices.append(modelMatrix)
        }
        
        
        // apply new intersection data to current tripple buffering buffer
        if let labelsWithIntersections = screenCollisionsDetector.getLabelsWithIntersections() {
            let geoLabels = labelsWithIntersections.geoLabels
            assembledMap.tileGeoLabels = geoLabels
            let intersections = labelsWithIntersections.intersections
            
            for i in 0..<assembledMap.tileGeoLabels.count {
                guard let intersections = intersections[i] else { continue }
                let tileGeoLabels = geoLabels[i]
                guard let textLabels = tileGeoLabels.textLabels else { continue }
                let copyToBuffer = textLabels.drawMapLabelsData.intersectionsTrippleBuffer[currentFBIdx]
                copyToBuffer.contents()
                            .copyMemory(from: intersections, byteCount: MemoryLayout<LabelIntersection>.stride * intersections.count)
            }
        }
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            renderComplete()
            return
        }
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.renderComplete()
        }
        
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.depthAttachment.texture = nil
        renderPassDescriptor.stencilAttachment.texture = nil
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.polygonPipeline.selectPipeline(renderEncoder: renderEncoder)
        assembledMapWrapper.drawTiles(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            modelMatrices: modelMatrices
        )
        renderEncoder.endEncoding()
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        renderPassDescriptor.depthAttachment.texture = view.depthStencilTexture
        renderPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
        let render3dEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.polygon3dPipeline.selectPipeline(renderEncoder: render3dEncoder)
        render3dEncoder.setDepthStencilState(depthStencilState)
        render3dEncoder.setStencilReferenceValue(0)
        assembledMapWrapper.draw3dTiles(
            renderEncoder: render3dEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            modelMatrices: modelMatrices
        )
        render3dEncoder.endEncoding()
        
        
        renderPassDescriptor.depthAttachment.texture = nil
        renderPassDescriptor.stencilAttachment.texture = nil
        let basicRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.labelsPipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        assembledMapWrapper.drawMapLabels(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            geoLabels: assembledMap.tileGeoLabels,
            currentFBIndex: currentFBIdx
        )
        
        pipelines.basePipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        drawPoint.draw(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: Settings.cameraCenterPointSize,
            position: camera.targetPosition,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        
        pipelines.textPipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        drawUI.drawZoomUiText(renderCommandEncoder: basicRenderEncoder, size: view.drawableSize)
        basicRenderEncoder.endEncoding()
        
        
        // Present the drawable to the screen
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
    
    private func renderComplete() {
        camera.updateBufferedUniform!.semaphore.signal()
    }
}
