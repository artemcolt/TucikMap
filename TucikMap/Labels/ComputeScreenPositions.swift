//
//  ComputeLabelScreen.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

import MetalKit

struct ComputeScreenPositions {
    let inputBuffer: MTLBuffer
    let outputBuffer: MTLBuffer
    let vertexCount: Int
    
    func readOutput() -> [SIMD2<Float>] {
        let outputPtr = outputBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: vertexCount)
        let output = Array(UnsafeBufferPointer(start: outputPtr, count: vertexCount))
        return output
    }
}

class ComputeLabelScreen {
    let metalDevice: MTLDevice!
    
    struct TransformUniforms {
        var worldViewMatrix: matrix_float4x4
        var worldProjectionMatrix: matrix_float4x4
        var viewportSize: SIMD2<Float>
    }
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
    }
    
    func transform(
        uniforms: MTLBuffer,
        computeEncoder: MTLComputeCommandEncoder,
        computeScreenPositions: ComputeScreenPositions,
    ) {
        let inputBuffer = computeScreenPositions.inputBuffer
        let outputBuffer = computeScreenPositions.outputBuffer
        let vertexCount = computeScreenPositions.vertexCount
        
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(uniforms, offset: 0, index: 2)
        
        let threadsPerGroup = MTLSize(
            width: 32,
            height: 1,
            depth: 1
        )
        let threadgroups = MTLSize(width: (vertexCount + threadsPerGroup.width - 1) / threadsPerGroup.width, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerGroup)
    }
}
