//
//  DrawPoint.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import SwiftUI
import MetalKit

class DrawPoint {
    var metalDevice: MTLDevice
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, pointSize: Float, position: SIMD3<Float>) {
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        
        // Create a simple square (two triangles) for the point, centered at the given position
        let halfSize = pointSize / 2
        // Triangle 1
        positions.append(SIMD3<Float>(position.x - halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y + halfSize, position.z))
        // Triangle 2
        positions.append(SIMD3<Float>(position.x - halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y + halfSize, position.z))
        positions.append(SIMD3<Float>(position.x - halfSize, position.y + halfSize, position.z))
        
        // Add red color for each vertex
        for _ in 0..<6 {
            colors.append(SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        }
        
        // Create temporary Metal buffers
        let positionBuffer = metalDevice.makeBuffer(bytes: positions,
                                                    length: positions.count * MemoryLayout<SIMD3<Float>>.stride,
                                                    options: .storageModeShared)
        
        let colorBuffer = metalDevice.makeBuffer(bytes: colors,
                                                 length: colors.count * MemoryLayout<SIMD4<Float>>.stride,
                                                 options: .storageModeShared)
        
        // Set vertex buffers
        renderEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        
        // Draw the point as two triangles (6 vertices)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
