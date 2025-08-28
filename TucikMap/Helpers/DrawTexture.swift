//
//  DrawTexture.swift
//  TucikMap
//
//  Created by Artem on 7/30/25.
//

import MetalKit

class DrawTexture {
    func draw(renderEncoder: MTLRenderCommandEncoder, texture: MTLTexture, sideWidth: Float) {
        let shift: Float = 100
        let vertices: [TexturePipeline.Vertex] = [
            // First triangle: 0, 1, 2
            TexturePipeline.Vertex(position: SIMD2<Float>( shift, shift), texCoord: SIMD2<Float>(0.0, 1.0)), // Bottom-left
            TexturePipeline.Vertex(position: SIMD2<Float>( sideWidth + shift, shift), texCoord: SIMD2<Float>(1.0, 1.0)), // Bottom-right
            TexturePipeline.Vertex(position: SIMD2<Float>( sideWidth + shift,  sideWidth + shift), texCoord: SIMD2<Float>(1.0, 0.0)), // Top-right
            
            // Second triangle: 0, 2, 3
            TexturePipeline.Vertex(position: SIMD2<Float>( shift, shift), texCoord: SIMD2<Float>(0.0, 1.0)), // Bottom-left
            TexturePipeline.Vertex(position: SIMD2<Float>( sideWidth + shift,  sideWidth + shift), texCoord: SIMD2<Float>(1.0, 0.0)), // Top-right
            TexturePipeline.Vertex(position: SIMD2<Float>( shift,  sideWidth + shift), texCoord: SIMD2<Float>(0.0, 0.0))  // Top-left
        ]
        renderEncoder.setVertexBytes(vertices, length: MemoryLayout<TexturePipeline.Vertex>.stride * vertices.count, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawBorders(renderEncoder: MTLRenderCommandEncoder, sideWidth: Float) {
        let shift: Float = 100
        let x1: Float = shift
        let y1: Float = shift
        let x2: Float = shift + sideWidth
        let y2: Float = shift + sideWidth
        let thickness: Float = 10
        let t: Float = thickness
        var positions: [SIMD3<Float>] = []
        // Bottom border (CCW triangles)
        positions.append(SIMD3(x2, y1 + t, 0))
        positions.append(SIMD3(x1, y1 + t, 0))
        positions.append(SIMD3(x1, y1, 0))
        positions.append(SIMD3(x2, y1, 0))
        positions.append(SIMD3(x2, y1 + t, 0))
        positions.append(SIMD3(x1, y1, 0))
        // Top border (CCW triangles)
        positions.append(SIMD3(x2, y2, 0))
        positions.append(SIMD3(x1, y2, 0))
        positions.append(SIMD3(x1, y2 - t, 0))
        positions.append(SIMD3(x2, y2 - t, 0))
        positions.append(SIMD3(x2, y2, 0))
        positions.append(SIMD3(x1, y2 - t, 0))
        // Left border (CCW triangles)
        positions.append(SIMD3(x1, y1, 0))
        positions.append(SIMD3(x1 + t, y1, 0))
        positions.append(SIMD3(x1 + t, y2, 0))
        positions.append(SIMD3(x1, y1, 0))
        positions.append(SIMD3(x1 + t, y2, 0))
        positions.append(SIMD3(x1, y2, 0))
        // Right border (CCW triangles)
        positions.append(SIMD3(x2, y1, 0))
        positions.append(SIMD3(x2, y2, 0))
        positions.append(SIMD3(x2 - t, y2, 0))
        positions.append(SIMD3(x2, y1, 0))
        positions.append(SIMD3(x2 - t, y2, 0))
        positions.append(SIMD3(x2 - t, y1, 0))
        
        let colors = positions.map { pos in SIMD4<Float>(1.0, 0.0, 0.0, 1.0) }
        renderEncoder.setVertexBytes(positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        renderEncoder.setVertexBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
    }
}
