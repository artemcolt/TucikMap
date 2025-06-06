//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class DrawAssembledMap {
    let mapSize = Settings.mapSize
    
    init(metalDevice: MTLDevice) {
        
    }
        
    func drawAssembledMap(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, map: AssembledMap) {
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for parsedTile in map.parsedTiles {
            let polygonBuffers = parsedTile.drawingPolygonBuffers
            renderEncoder.setVertexBuffer(polygonBuffers.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(parsedTile.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBuffer(parsedTile.modelMatrixBuffer, offset: 0, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: polygonBuffers.indicesCount,
                indexType: .uint32,
                indexBuffer: polygonBuffers.indicesBuffer,
                indexBufferOffset: 0)
        }
    }
}
