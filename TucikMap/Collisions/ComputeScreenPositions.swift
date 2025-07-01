//
//  ComputeScreenPositions.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

struct InputComputeScreenVertex {
    let location: SIMD2<Float>
    let matrixId: simd_short1
}

struct ComputeScreenPositions {
    let inputModelMatricesBuffer: MTLBuffer
    let inputBuffer: MTLBuffer
    let outputBuffer: MTLBuffer
    let vertexCount: Int
    let readVerticesCount: Int
    
    func readOutput() -> [SIMD2<Float>] {
        let outputPtr = outputBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: readVerticesCount)
        let output = Array(UnsafeBufferPointer(start: outputPtr, count: readVerticesCount))
        return output
    }
}

class ComputeLabelScreen {
    let metalDevice: MTLDevice!
    let computeScreenPipeline: ComputeScreenPipeline
    
    struct TransformUniforms {
        var worldViewMatrix: matrix_float4x4
        var worldProjectionMatrix: matrix_float4x4
        var viewportSize: SIMD2<Float>
    }
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        self.metalDevice = metalDevice
        
        computeScreenPipeline = ComputeScreenPipeline(metalDevice: metalDevice, library: library)
    }
    
    func compute(
        uniforms: MTLBuffer,
        computeEncoder: MTLComputeCommandEncoder,
        computeScreenPositions: ComputeScreenPositions,
    ) {
        computeScreenPipeline.selectComputePipeline(computeEncoder: computeEncoder)
        let inputBuffer = computeScreenPositions.inputBuffer
        let outputBuffer = computeScreenPositions.outputBuffer
        let vertexCount = computeScreenPositions.vertexCount
        let inputModelMatricesBuffer = computeScreenPositions.inputModelMatricesBuffer
        
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(uniforms, offset: 0, index: 2)
        computeEncoder.setBuffer(inputModelMatricesBuffer, offset: 0, index: 3)
        
        let threadsPerGroup = MTLSize(
            width: 32,
            height: 1,
            depth: 1
        )
        let threadgroups = MTLSize(width: (vertexCount + threadsPerGroup.width - 1) / threadsPerGroup.width, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerGroup)
    }
}
