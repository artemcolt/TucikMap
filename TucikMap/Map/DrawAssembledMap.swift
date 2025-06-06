//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class DrawAssembledMap {
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    private var map: AssembledMap?
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
    }
    
    func setCurrentAssembledMap(assembledMap: AssembledMap?) {
        self.map = assembledMap
    }
    
    func drawAssembledMap(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer
    ) {
        guard let map = map else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for tile in map.tiles {
            renderEncoder.setVertexBuffer(tile.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBuffer(tile.modelMatrixBuffer, offset: 0, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: tile.indicesCount,
                indexType: .uint32,
                indexBuffer: tile.indicesBuffer,
                indexBufferOffset: 0)
        }
    }
}
