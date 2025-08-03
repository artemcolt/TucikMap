//
//  DrawAxes.swift
//  TucikMap
//
//  Created by Grok on 8/3/25.
//

import SwiftUI
import MetalKit

class DrawAxes {
    var metalDevice: MTLDevice
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
    }
    
    func draw(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        lineLength: Float,
        position: SIMD3<Float>
    ) {
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        
        // X axis (red)
        positions.append(position)
        positions.append(position + SIMD3<Float>(lineLength, 0, 0))
        colors.append(SIMD4<Float>(1, 0, 0, 1))
        colors.append(SIMD4<Float>(1, 0, 0, 1))
        
        // Y axis (green)
        positions.append(position)
        positions.append(position + SIMD3<Float>(0, lineLength, 0))
        colors.append(SIMD4<Float>(0, 1, 0, 1))
        colors.append(SIMD4<Float>(0, 1, 0, 1))
        
        // Z axis (blue)
        positions.append(position)
        positions.append(position + SIMD3<Float>(0, 0, lineLength))
        colors.append(SIMD4<Float>(0, 0, 1, 1))
        colors.append(SIMD4<Float>(0, 0, 1, 1))
        
        // Set vertex buffers
        renderEncoder.setVertexBytes(&positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        renderEncoder.setVertexBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        
        // Draw the axes as three separate lines (6 vertices)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 6)
    }
}
