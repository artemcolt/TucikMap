//
//  TransformToScreenPipeline.swift
//  TucikMap
//
//  Created by Artem on 6/11/25.
//

import MetalKit

class TransformWorldToScreenPositionPipeline {
    private(set) var pipelineState: MTLComputePipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let kernel = library.makeFunction(name: "transformKernel")!
        
        pipelineState = try! metalDevice.makeComputePipelineState(function: kernel)
    }
    
    func selectComputePipeline(computeEncoder: MTLComputeCommandEncoder) {
        computeEncoder.setComputePipelineState(pipelineState)
    }
}
