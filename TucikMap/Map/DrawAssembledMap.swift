//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit
import Foundation

class DrawAssembledMap {
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    let drawMapLabels: DrawMapLabels
    let camera: Camera
    let mapZoomState: MapZoomState
    let sampler: MTLSamplerState
    var screenUniforms: ScreenUniforms
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.drawMapLabels = DrawMapLabels(metalDevice: metalDevice, screenUniforms: screenUniforms, camera: camera, mapZoomState: mapZoomState)
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
        tileModelMatrices: TileModelMatrices
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for tile in tiles {
            var modelMatrix = tileModelMatrices.get(tile: tile.tile)
            let tile2dBuffers = tile.tile2dBuffers
            
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
        tileModelMatrices: TileModelMatrices
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for tile in tiles {
            let tileBuffers = tile.tile3dBuffers
            guard let verticesBuffer = tileBuffers.verticesBuffer,
                  let indicesBuffer = tileBuffers.indicesBuffer,
                  let stylesBuffer = tileBuffers.stylesBuffer else { continue }
            var modelMatrix = tileModelMatrices.get(tile: tile.tile)
            
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
        tileModelMatrices: TileModelMatrices
    ) {
        drawMapLabels.draw(
            renderEncoder: renderEncoder,
            geoLabels: geoLabels,
            uniformsBuffer: uniformsBuffer,
            currentFBIndex: currentFBIndex,
            tileModelMatrices: tileModelMatrices
        )
    }
    
    func drawRoadLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        roadLabelsDrawing: [FinalDrawRoadLabel],
        currentFBIndex: Int,
        tileModelMatrices: TileModelMatrices
    ) {
        guard roadLabelsDrawing.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 4)
        
        let drawTiles = roadLabelsDrawing
        for finalDraw in drawTiles {
            let metalRoad = finalDraw.metalRoadLabels
            let instances = finalDraw.maxInstances
            guard let roadLabels = metalRoad.roadLabels else { continue }
            let draw = roadLabels.drawMapLabelsData
            let tile = metalRoad.tile
            var modelMatrix = tileModelMatrices.get(tile: tile)
            
            let vertexBuffer = draw.vertexBuffer
            let verticesCount = draw.verticesCount
            let mapLabelSymbolMeta = draw.mapLabelSymbolMeta
            let mapLabelLineMeta = draw.mapLabelLineMeta
            let localPositions = draw.localPositionsBuffer
            let atlasTexture = draw.atlas
            guard instances > 0 else { continue }
            
            let startRoadAtBuffer = draw.startRoadAtBuffer[currentFBIndex]
            let lineToStartFloatsBuffer = draw.lineToStartFloatsBuffer[currentFBIndex]
            
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(mapLabelSymbolMeta, offset: 0, index: 2)
            renderEncoder.setVertexBuffer(mapLabelLineMeta, offset: 0, index: 3)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 5)
            renderEncoder.setVertexBuffer(localPositions, offset: 0, index: 6)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            renderEncoder.setVertexBuffer(lineToStartFloatsBuffer, offset: 0, index: 7)
            renderEncoder.setVertexBuffer(startRoadAtBuffer, offset: 0, index: 8)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount, instanceCount: instances)
        }
    }
}
