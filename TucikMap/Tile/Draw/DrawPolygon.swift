//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//
import MetalKit

class DrawPolygon {
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, drawingPolygonFeature: [AssembledMapFeature]) {
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        for feature in drawingPolygonFeature {
            var color = feature.featureStyle.color
            // Set vertex buffers
            renderEncoder.setVertexBuffer(feature.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: feature.indexCount,
                indexType: feature.indexType,
                indexBuffer: feature.indicesBuffer,
                indexBufferOffset: 0
            )
        }
    }
}
