//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class DrawAssembledMap {
    let mapSize = Settings.mapSize
    private let indirectCommandBuffer: MTLIndirectCommandBuffer
    
    init(metalDevice: MTLDevice) {
        let icbDescriptor = MTLIndirectCommandBufferDescriptor()
        icbDescriptor.commandTypes = .drawIndexed
        icbDescriptor.inheritPipelineState = true
        icbDescriptor.maxVertexBufferBindCount = 4
        
        indirectCommandBuffer = metalDevice.makeIndirectCommandBuffer(
            descriptor: icbDescriptor,
            maxCommandCount: Settings.visibleTilesCount * DetermineFeatureStyle.stylesNumber
        )!
    }
        
    func drawAssembledMap(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, map: AssembledMap) {
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        var commandIndex = 0
        for styleKey in map.allStyles {
            for parsedTile in map.parsedTiles {
                guard let style = parsedTile.styles[styleKey] else {continue}
                
                let polygonBuffers = parsedTile.drawingPolygonBuffers[styleKey]!
                var modelMatrixBuffer = parsedTile.modelMatrixBuffer
                var color = style.color
                renderEncoder.setVertexBuffer(polygonBuffers.verticesBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
                renderEncoder.setVertexBuffer(modelMatrixBuffer, offset: 0, index: 3)
                
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: polygonBuffers.indicesCount,
                    indexType: .uint32,
                    indexBuffer: polygonBuffers.indicesBuffer,
                    indexBufferOffset: 0
                )
            }
        }
        
    }
}
