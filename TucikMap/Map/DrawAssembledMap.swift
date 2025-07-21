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
        let metalRoadLabels: MetalRoadLabels
        let maxInstances: Int
    }
    
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    let camera: Camera
    let mapZoomState: MapZoomState
    let sampler: MTLSamplerState
    var screenUniforms: ScreenUniforms
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera, mapZoomState: MapZoomState) {
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
        tileFrameProps: TileFrameProps
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for tile in tiles {
            let tileProps       = tileFrameProps.get(tile: tile.tile)
            guard tileProps.contains else { continue }
                    
            var modelMatrix     = tileProps.model
            let tile2dBuffers   = tile.tile2dBuffers
            
            renderEncoder.setVertexBuffer(tile2dBuffers.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile2dBuffers.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: tile2dBuffers.indicesCount,
                indexType: .uint32,
                indexBuffer: tile2dBuffers.indicesBuffer,
                indexBufferOffset: 0
            )
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
            let tile = metalTile.tile
            let props = tileFrameProps.get(tile: tile)
            guard props.contains else { continue }
            var modelMatrix = props.model
            
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: tileBuffers.indicesCount,
                indexType: .uint32,
                indexBuffer: indicesBuffer,
                indexBufferOffset: 0)
        }
    }
    
    func drawMapLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        geoLabels: [MetalGeoLabels],
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
            
            let tile                    = metalTile.tile
            let props                   = tileFrameProps.get(tile: tile)
            guard props.contains else { continue }
            
            var modelMatrix             = props.model
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
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 7)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
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
            let tileProps               = tileFrameProps.get(tile: tile)
            
            guard tileProps.contains else { continue }
            
            var modelMatrix             = tileProps.model
            
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
            
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 5)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount, instanceCount: instances)
        }
    }
}
