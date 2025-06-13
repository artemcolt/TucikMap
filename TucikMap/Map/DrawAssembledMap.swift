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
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms) {
        self.metalDevice = metalDevice
        self.drawMapLabels = DrawMapLabels(metalDevice: metalDevice, screenUniforms: screenUniforms)
    }
    
    func drawTiles(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile]
    ) {
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        for tile in tiles {
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
    
    func drawMapLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniforms: MTLBuffer,
        drawLabelsData: DrawMapLabelsData?
    ) {
        if let drawLabelsData = drawLabelsData {
            drawMapLabels.draw(
                renderEncoder: renderEncoder,
                drawMapLabelsData: drawLabelsData,
                uniforms: uniforms
            )
        }
    }
}
