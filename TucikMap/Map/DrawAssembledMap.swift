//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit
import Foundation

class DrawAssembledMap {
    struct FinalDrawRoadLabel {
        let metalRoadLabels: MetalTile.RoadLabels
        let maxInstances: Int
    }
    
    let metalDevice: MTLDevice
    let camera: CameraFlatView
    let mapZoomState: MapZoomState
    let sampler: MTLSamplerState
    var screenUniforms: ScreenUniforms
    let drawTile = DrawTile()
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: CameraFlatView, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.mapZoomState = mapZoomState
        self.camera = camera
        self.screenUniforms = screenUniforms
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    func drawTiles(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile],
        areaRange: AreaRange,
        tileFrameProps: TileFrameProps
    ) {
        guard tiles.isEmpty == false else { return }
        drawTile.setUniforms(renderEncoder: renderEncoder, uniformsBuffer: uniformsBuffer)
        
        for tile in tiles {
            let tile2dBuffers = tile.tile2dBuffers
            drawTile.setTileConsts(renderEncoder: renderEncoder, tile2dBuffers: tile2dBuffers)
            for loop in -1...1 {
                let tileProps       = tileFrameProps.get(tile: tile.tile, loop: loop)
                let tileModelMatrix = tileProps.model
                guard tileProps.frustrumPassed else { continue }
                
                drawTile.draw(renderEncoder: renderEncoder, modelMatrix: tileModelMatrix, tile2dBuffers: tile2dBuffers)
            }
        }
    }
    
    func draw3dTiles(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile],
        tileFrameProps: TileFrameProps
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        
        for metalTile in tiles {
            let tileBuffers = metalTile.tile3dBuffers
            guard let verticesBuffer = tileBuffers.verticesBuffer,
                  let indicesBuffer = tileBuffers.indicesBuffer,
                  let stylesBuffer = tileBuffers.stylesBuffer else { continue }
            
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(stylesBuffer, offset: 0, index: 2)
            
            for loop in -1...1 {
                let tile = metalTile.tile
                let props = tileFrameProps.get(tile: tile, loop: loop)
                guard props.frustrumPassed else { continue }
                var modelMatrix = props.model
                renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 3)
                
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: tileBuffers.indicesCount,
                    indexType: .uint32,
                    indexBuffer: indicesBuffer,
                    indexBufferOffset: 0)
            }
        }
    }
    
    func drawMapLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        geoLabels: [MetalTile.TextLabels],
        currentFBIndex: Int,
        tileFrameProps: TileFrameProps
    ) {
        guard geoLabels.isEmpty == false else { return }
        
        var animationTime = Settings.labelsFadeAnimationTimeSeconds
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride,   index: 6)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer,       offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer,                           offset: 0, index: 4)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        for metalTile in geoLabels {
            guard let textLabels        = metalTile.textLabels else { continue }
            
            let metalDrawMapLabels      = textLabels.metalDrawMapLabels
            let vertexBuffer            = metalDrawMapLabels.vertexBuffer
            let verticesCount           = metalDrawMapLabels.verticesCount
            let mapLabelSymbolMeta      = metalDrawMapLabels.mapLabelSymbolMeta
            let mapLabelGpuMeta         = metalDrawMapLabels.mapLabelGpuMeta
            let intersectionsBuffer     = metalDrawMapLabels.intersectionsTrippleBuffer[currentFBIndex]
            let atlasTexture            = metalDrawMapLabels.atlas
            
            renderEncoder.setVertexBuffer(vertexBuffer,         offset: 0, index: 0)
            renderEncoder.setVertexBuffer(mapLabelSymbolMeta,   offset: 0, index: 2)
            renderEncoder.setVertexBuffer(mapLabelGpuMeta,      offset: 0, index: 3)
            renderEncoder.setVertexBuffer(intersectionsBuffer,  offset: 0, index: 5)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            let tile = metalTile.tile
            let props = tileFrameProps.get(tile: tile, loop: 0)
            guard props.frustrumPassed else { continue }
            var modelMatrix = props.model
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 7)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
        }
    }
    
    func drawRoadLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        roadLabelsDrawing: [FinalDrawRoadLabel],
        currentFBIndex: Int,
        tileFrameProps: TileFrameProps
    ) {
        var animationTime = Settings.labelsFadeAnimationTimeSeconds
        guard roadLabelsDrawing.isEmpty == false else { return }
        
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer,                     offset: 0, index: 4)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        var rotationYaw = (camera.rotationYaw - Float.pi / 2).truncatingRemainder(dividingBy: 2 * Float.pi)
        renderEncoder.setVertexBytes(&rotationYaw, length: MemoryLayout<Float>.size,             index: 9)
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride,         index: 11)
        
        for finalDraw in roadLabelsDrawing {
            let metalRoad               = finalDraw.metalRoadLabels
            let instances               = finalDraw.maxInstances
            
            guard let roadLabels        = metalRoad.roadLabels else { continue }
            
            let draw                    = roadLabels.draw
            let tile                    = metalRoad.tile
            
            
            let vertexBuffer            = draw.vertexBuffer
            let verticesCount           = draw.verticesCount
            let mapLabelSymbolMeta      = draw.mapLabelSymbolMeta
            let mapLabelLineMeta        = draw.mapLabelGpuMeta
            let localPositions          = draw.localPositionsBuffer
            let atlasTexture            = draw.atlas
            
            guard instances > 0 else { continue }
            
            let startRoadAtBuffer       = draw.startRoadAtBuffer[currentFBIndex]
            let lineToStartFloatsBuffer = draw.lineToStartFloatsBuffer[currentFBIndex]
            let intersectionsBuffer     = draw.intersectionsTrippleBuffer[currentFBIndex]
            
            renderEncoder.setVertexBuffer(vertexBuffer,             offset: 0, index: 0)
            renderEncoder.setVertexBuffer(mapLabelSymbolMeta,       offset: 0, index: 2)
            renderEncoder.setVertexBuffer(mapLabelLineMeta,         offset: 0, index: 3)
            renderEncoder.setVertexBuffer(localPositions,           offset: 0, index: 6)
            renderEncoder.setVertexBuffer(lineToStartFloatsBuffer,  offset: 0, index: 7)
            renderEncoder.setVertexBuffer(startRoadAtBuffer,        offset: 0, index: 8)
            renderEncoder.setVertexBuffer(intersectionsBuffer,      offset: 0, index: 10)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            let tileProps = tileFrameProps.get(tile: tile, loop: 0)
            guard tileProps.frustrumPassed else { continue }
            var modelMatrix = tileProps.model
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 5)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount, instanceCount: instances)
        }
    }
}
