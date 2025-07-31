//
//  DrawTexture.swift
//  TucikMap
//
//  Created by Artem on 7/30/25.
//

import MetalKit

class DrawTexture {
    private let screenUniforms: ScreenUniforms
    
    init(screenUniforms: ScreenUniforms) {
        self.screenUniforms = screenUniforms
    }
    
    func draw(textureEncoder: MTLRenderCommandEncoder, texture: MTLTexture, sideWidth: Float) {
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
        textureEncoder.setVertexBytes(vertices, length: MemoryLayout<TexturePipeline.Vertex>.stride * vertices.count, index: 0)
        textureEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        textureEncoder.setFragmentTexture(texture, index: 0)
        textureEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawBorders(textureEncoder: MTLRenderCommandEncoder, sideWidth: Float) {
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
        textureEncoder.setVertexBytes(positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        textureEncoder.setVertexBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 1)
        textureEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 2)
        textureEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
    }
}
