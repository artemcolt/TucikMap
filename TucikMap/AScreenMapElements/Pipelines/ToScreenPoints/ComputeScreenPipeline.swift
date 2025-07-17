//
//  CompueScreenPipeline.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

class ComputeScreenPipeline {
    private(set) var pipelineState: MTLComputePipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let kernel = library.makeFunction(name: "computeScreens")!
        
        pipelineState = try! metalDevice.makeComputePipelineState(function: kernel)
    }
    
    func selectComputePipeline(computeEncoder: MTLComputeCommandEncoder) {
        computeEncoder.setComputePipelineState(pipelineState)
    }
}
