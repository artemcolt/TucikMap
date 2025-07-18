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
    
    var depthStencilStatePrePass: MTLDepthStencilState!
    var depthStencilStateColorPass: MTLDepthStencilState!
    
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
    var applyLabelsState: ApplyLabelsState!
    
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
            
            let depthPrePassDescriptor = MTLDepthStencilDescriptor()
            depthPrePassDescriptor.depthCompareFunction = .less
            depthPrePassDescriptor.isDepthWriteEnabled = true
            depthStencilStatePrePass = device.makeDepthStencilState(descriptor: depthPrePassDescriptor)
            
            let depthColorPassDescriptor = MTLDepthStencilDescriptor()
            depthColorPassDescriptor.depthCompareFunction = .equal  // Key change: only equal depths pass
            depthColorPassDescriptor.isDepthWriteEnabled = false   // No need to write depth again
            // Настройка stencil-теста
            let stencilDescriptor = MTLStencilDescriptor()
            stencilDescriptor.stencilCompareFunction = .equal
            stencilDescriptor.stencilFailureOperation = .keep
            stencilDescriptor.depthFailureOperation = .keep
            stencilDescriptor.depthStencilPassOperation = .incrementClamp // Увеличиваем stencil при рендеринге
            stencilDescriptor.readMask = 0xFF
            stencilDescriptor.writeMask = 0xFF
            depthColorPassDescriptor.frontFaceStencil = stencilDescriptor
            depthStencilStateColorPass = device.makeDepthStencilState(descriptor: depthColorPassDescriptor)!
            
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
                screenCollisionsDetector: screenCollisionsDetector
            )
            assembledMapWrapper = DrawAssembledMap(
                metalDevice: metalDevice,
                screenUniforms: screenUniforms,
                camera: camera,
                mapZoomState: mapZoomState
            )
            applyLabelsState = ApplyLabelsState(screenCollisionsDetector: screenCollisionsDetector, assembledMap: camera.assembledMapUpdater.assembledMap)
            drawUI = DrawUI(device: device, textTools: textTools, mapZoomState: mapZoomState, screenUniforms: screenUniforms)
            self.renderFrameControl = RenderFrameControl(mapCADisplayLoop: camera.mapCadDisplayLoop, renderFrameCount: renderFrameCount)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderFrameControl.updateView(view: view)
        
        // Handle viewport size changes - update all uniform buffers
        screenUniforms.update(size: size)
        camera.updateMap(view: view, size: size)
        
        if Settings.useGoToAtStart {
            let goToLocationAtStart = Settings.goToLocationAtStart
            let zoom = Settings.goToAtStartZ
            camera.moveTo(lat: goToLocationAtStart.x, lon: goToLocationAtStart.y, zoom: zoom, view: view, size: size)
        }
        
        
        //let panningPoint = Tile(x: 9904, y: 5122, z: 14).getTilePointPanningCoordinates(normalizedX: -1, normalizedY: 0)
        //camera.moveToPanningPoint(point: panningPoint, zoom: 14, view: view, size: size)
    }
    
    
    // Three-step rendering process
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = camera.updateBufferedUniform!.semaphore.wait(timeout: .distantFuture)
        
        let updateBufferedUniform = camera.updateBufferedUniform!
        updateBufferedUniform.updateUniforms(viewportSize: view.drawableSize)
        camera.updateMapState(view: view)
        
        let currentFBIdx            = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer          = updateBufferedUniform.getCurrentFrameBuffer()
        let assembledMap            = camera.assembledMapUpdater.assembledMap
        let assembledTiles          = assembledMap.tiles
        let mapPanning              = camera.mapPanning
        let tileFrameProps          = TileFrameProps(mapZoomState: mapZoomState,
                                                     pan: mapPanning,
                                                     uniforms: updateBufferedUniform.lastUniforms!)
        
        // Применяем если есть актуальные данные меток для свежего кадра
        applyLabelsState.apply(currentFBIdx: currentFBIdx)
        
        
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
            tileFrameProps: tileFrameProps
        )
        renderEncoder.endEncoding()
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let roadLabelsEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.roadLabelPipeline.selectPipeline(renderEncoder: roadLabelsEncoder)
        assembledMapWrapper.drawRoadLabels(
            renderEncoder: roadLabelsEncoder,
            uniformsBuffer: uniformsBuffer,
            roadLabelsDrawing: assembledMap.roadLabels,
            currentFBIndex: currentFBIdx,
            tileFrameProps: tileFrameProps
        )
        roadLabelsEncoder.endEncoding()
        
        
        
        // First: Depth pre-pass (populate min depths, no color)
        let depthPrePassDescriptor = renderPassDescriptor.copy() as! MTLRenderPassDescriptor  // Copy the original
        depthPrePassDescriptor.depthAttachment.texture = view.depthStencilTexture
        depthPrePassDescriptor.stencilAttachment.texture = view.depthStencilTexture
        depthPrePassDescriptor.colorAttachments[0].loadAction = .dontCare  // No color load needed
        depthPrePassDescriptor.colorAttachments[0].storeAction = .dontCare // Disable color writes
        depthPrePassDescriptor.depthAttachment.loadAction = .clear         // Clear depth
        depthPrePassDescriptor.depthAttachment.storeAction = .store        // Keep depth for next pass
        depthPrePassDescriptor.depthAttachment.clearDepth = 1.0
        let depthPrePassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthPrePassDescriptor)!
        pipelines.polygon3dPipeline.selectPipeline(renderEncoder: depthPrePassEncoder)
        depthPrePassEncoder.setDepthStencilState(depthStencilStatePrePass)
        depthPrePassEncoder.setCullMode(.back)
        assembledMapWrapper.draw3dTiles(
            renderEncoder: depthPrePassEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        depthPrePassEncoder.endEncoding()
        
        // Second: Color pass (draw only frontmost, with blending)
        let colorPassDescriptor = renderPassDescriptor.copy() as! MTLRenderPassDescriptor  // Copy again
        colorPassDescriptor.depthAttachment.texture = view.depthStencilTexture
        colorPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
        colorPassDescriptor.colorAttachments[0].loadAction = .load  // Or .load if you have prior content
        colorPassDescriptor.colorAttachments[0].storeAction = .store // Write colors
        colorPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // Background color
        colorPassDescriptor.depthAttachment.loadAction = .load       // Use pre-pass depths
        colorPassDescriptor.depthAttachment.storeAction = .dontCare  // No need after
        let colorPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: colorPassDescriptor)!
        pipelines.polygon3dPipeline.selectPipeline(renderEncoder: colorPassEncoder)
        colorPassEncoder.setDepthStencilState(depthStencilStateColorPass)
        colorPassEncoder.setStencilReferenceValue(0)
        colorPassEncoder.setCullMode(.back)
        assembledMapWrapper.draw3dTiles(
            renderEncoder: colorPassEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        colorPassEncoder.endEncoding()
        
        
        let basicRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.labelsPipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        assembledMapWrapper.drawMapLabels(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            geoLabels: assembledMap.tileGeoLabels,
            currentFBIndex: currentFBIdx,
            tileFrameProps: tileFrameProps
        )
        
        pipelines.basePipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        drawPoint.draw(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: Settings.cameraCenterPointSize,
            position: camera.targetPosition,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        
        let testPoints = screenCollisionsDetector.testPoints
        for point in testPoints {
            let color = SIMD4<Float>(0.0, 1.0, 0.0, 1.0)
            drawPoint.draw(
                renderEncoder: basicRenderEncoder,
                uniformsBuffer: screenUniforms.screenUniformBuffer,
                pointSize: 15,
                position: SIMD3<Float>(point.x, point.y, 0),
                color: color
            )
        }
        
        
        if Settings.drawRoadPointsDebug {
            drawRoadPoints(assembledMap: assembledMap,
                           tileFrameProps: tileFrameProps,
                           basicRenderEncoder: basicRenderEncoder,
                           uniformsBuffer: uniformsBuffer)
        }
        
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
    
    private var colors: [String: SIMD4<Float>] = [:]
    private func drawRoadPoints(
        assembledMap: AssembledMap,
        tileFrameProps: TileFrameProps,
        basicRenderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer
    ) {
        for i in 0..<assembledMap.roadLabels.count {
            let tileRoadLabels = assembledMap.roadLabels[i]
            let metalRoadLabels = tileRoadLabels.metalRoadLabels
            let tile = metalRoadLabels.tile
            guard let roadLabels = metalRoadLabels.roadLabels else { continue }
            let props = tileFrameProps.get(tile: tile)
            let modelMatrix = props.model
            guard props.contains else { continue } 
            let metas = roadLabels.mapLabelsCpuMeta
            
            for i2 in 0..<metas.count {
                let key = "\(i)\(i2)"
                var color = colors[key]
                if color == nil {
                    let randomColor = SIMD4<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1.0)
                    colors[key] = randomColor
                    color = randomColor
                }
                
                let meta = metas[i2]
                let localPositions = meta.localPositions
                for point in localPositions {
                    let pointToDraw = modelMatrix * SIMD4<Float>(point.x, point.y, 0, 1)
                    drawPoint.draw(
                        renderEncoder: basicRenderEncoder,
                        uniformsBuffer: uniformsBuffer,
                        pointSize: Settings.cameraCenterPointSize * 0.5,
                        position: SIMD3<Float>(pointToDraw.x, pointToDraw.y, 0),
                        color: color!,
                    )
                }
            }
        }
    }
}
