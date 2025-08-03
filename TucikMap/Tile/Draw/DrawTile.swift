//
//  DrawTile.swift
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

import MetalKit

class DrawTile {
    func setUniforms(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer) {
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
    }
    
    func setTileConsts(renderEncoder: MTLRenderCommandEncoder, tile2dBuffers: Tile2dBuffers) {
        renderEncoder.setVertexBuffer(tile2dBuffers.verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(tile2dBuffers.stylesBuffer,   offset: 0, index: 2)
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, modelMatrix: matrix_float4x4, tile2dBuffers: Tile2dBuffers) {
        var modelMatrix = modelMatrix
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
