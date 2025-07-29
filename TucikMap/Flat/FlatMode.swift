//
//  FlatMode.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import SwiftUI
import MetalKit

class FlatMode {
    private var metalDevice                 : MTLDevice!
    private var metalCommandQueue           : MTLCommandQueue!
    private var updateBufferedUniform       : UpdateBufferedUniform!
    private var mapUpdaterFlat              : MapUpdaterFlat
    private var mapCadDisplayLoop           : MapCADisplayLoop
    private var screenCollisionsDetector    : ScreenCollisionsDetector
    
    var depthStencilStatePrePass        : MTLDepthStencilState!
    var depthStencilStateColorPass      : MTLDepthStencilState!
    
    // Helpers
    var drawPoint: DrawPoint
    
    // Tile
    var drawAssembledMap: DrawAssembledMap!
    
    // Map
    var camera: CameraFlatView!
    var applyLabelsState: ApplyLabelsState!
    var mapZoomState: MapZoomState
    
    // UI
    var pipelines: Pipelines
    
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         frameCounter: FrameCounter,
         drawingFrameRequester: DrawingFrameRequester,
         textTools: TextTools,
         metalTilesStorage: MetalTilesStorage,
         mapCadDisplayLoop: MapCADisplayLoop,
         screenUniforms: ScreenUniforms,
         cameraStorage: CameraStorage,
         pipelines: Pipelines,
         mapZoomState: MapZoomState,
         updateBufferedUniform: UpdateBufferedUniform,
         mapModeStorage: MapModeStorage,
         drawPoint: DrawPoint,
         screenCollisionsDetector: ScreenCollisionsDetector,
         mapUpdaterFlat: MapUpdaterFlat) {
        
        self.drawPoint                  = drawPoint
        self.pipelines                  = pipelines
        self.metalDevice                = metalDevice
        self.metalCommandQueue          = metalCommandQueue
        self.mapCadDisplayLoop          = mapCadDisplayLoop
        self.mapZoomState               = mapZoomState
        self.updateBufferedUniform      = updateBufferedUniform
        self.mapUpdaterFlat             = mapUpdaterFlat
        self.screenCollisionsDetector   = screenCollisionsDetector
        
        let depthPrePassDescriptor  = MTLDepthStencilDescriptor()
        depthPrePassDescriptor.depthCompareFunction = .less
        depthPrePassDescriptor.isDepthWriteEnabled = true
        depthStencilStatePrePass = metalDevice.makeDepthStencilState(descriptor: depthPrePassDescriptor)
        
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
        depthStencilStateColorPass = metalDevice.makeDepthStencilState(descriptor: depthColorPassDescriptor)!
        
        camera                      = cameraStorage.flatView
        
        drawAssembledMap            = DrawAssembledMap(metalDevice: metalDevice,
                                                       screenUniforms: screenUniforms,
                                                       camera: camera,
                                                       mapZoomState: mapZoomState)
        
        applyLabelsState            = ApplyLabelsState(screenCollisionsDetector: screenCollisionsDetector,
                                                       assembledMap: mapUpdaterFlat.assembledMap)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        //let panningPoint = Tile(x: 9904, y: 5122, z: 14).getTilePointPanningCoordinates(normalizedX: -1, normalizedY: 0)
        //camera.moveToPanningPoint(point: panningPoint, zoom: 14, view: view, size: size)
    }
    
    // Three-step rendering process
    func draw(in view: MTKView,
              renderPassDescriptor: MTLRenderPassDescriptor,
              commandBuffer: MTLCommandBuffer) {
        
        let currentFBIdx            = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer          = updateBufferedUniform.getCurrentFrameBuffer()
        let assembledMap            = mapUpdaterFlat.assembledMap
        let assembledTiles          = assembledMap.tiles
        let mapPanning              = camera.mapPanning
        let lastUniforms            = updateBufferedUniform.lastUniforms!
        let tileFrameProps          = TileFrameProps(mapZoomState: mapZoomState,
                                                     pan: mapPanning,
                                                     uniforms: lastUniforms)
        
        if (mapCadDisplayLoop.checkEvaluateScreenData()) {
            let _ = screenCollisionsDetector.evaluate(lastUniforms: lastUniforms, mapPanning: mapPanning)
        }
        
        
        // Применяем если есть актуальные данные меток для свежего кадра
        applyLabelsState.apply(currentFBIdx: currentFBIdx)
        
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.depthAttachment.texture = nil
        renderPassDescriptor.stencilAttachment.texture = nil
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.polygonPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawAssembledMap.drawTiles(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        renderEncoder.endEncoding()
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let roadLabelsEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.roadLabelPipeline.selectPipeline(renderEncoder: roadLabelsEncoder)
        drawAssembledMap.drawRoadLabels(
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
        drawAssembledMap.draw3dTiles(
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
        drawAssembledMap.draw3dTiles(
            renderEncoder: colorPassEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        colorPassEncoder.endEncoding()
        
        
        let basicRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.labelsPipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        drawAssembledMap.drawMapLabels(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            geoLabels: assembledMap.tileGeoLabels,
            currentFBIndex: currentFBIdx,
            tileFrameProps: tileFrameProps
        )
        
//        let testPoints = screenCollisionsDetector.testPoints
//        for point in testPoints {
//            let color = SIMD4<Float>(0.0, 1.0, 0.0, 1.0)
//            drawPoint.draw(
//                renderEncoder: basicRenderEncoder,
//                uniformsBuffer: screenUniforms.screenUniformBuffer,
//                pointSize: 15,
//                position: SIMD3<Float>(point.x, point.y, 0),
//                color: color
//            )
//        }
        
        
        if Settings.drawRoadPointsDebug {
            drawRoadPoints(assembledMap: assembledMap,
                           tileFrameProps: tileFrameProps,
                           basicRenderEncoder: basicRenderEncoder,
                           uniformsBuffer: uniformsBuffer)
        }
        
        basicRenderEncoder.endEncoding()
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
