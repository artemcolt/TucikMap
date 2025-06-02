//
//  DrawTestCube.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit

class DrawTestCube {
    // Buffers
    var positionBuffer: MTLBuffer!
    var colorBuffer: MTLBuffer!
    var metalDevice: MTLDevice
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        createGeometryBuffers()
    }
    
    func createGeometryBuffers() {
        let geometry = GeometryUtils.createCubeGeometryBuffers()
        let positions = geometry.0
        let colors = geometry.1
        
        // Create Metal buffers from our position and color arrays
        positionBuffer = metalDevice.makeBuffer(bytes: positions,
                                               length: positions.count * MemoryLayout<SIMD3<Float>>.stride,
                                               options: .storageModeShared)
        
        colorBuffer = metalDevice.makeBuffer(bytes: colors,
                                           length: colors.count * MemoryLayout<SIMD4<Float>>.stride,
                                           options: .storageModeShared)
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer) {
        renderEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)
    }
    
}
