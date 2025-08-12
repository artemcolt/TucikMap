//
//  TextureAdderPipeline.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class TextureAdderPipeline {
    let pipelineState: MTLComputePipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let kernelFunction = library.makeFunction(name: "add_textures")!
        
        pipelineState = try! metalDevice.makeComputePipelineState(function: kernelFunction)
    }
    
    func selectPipeline(computeEncoder: MTLComputeCommandEncoder) {
        computeEncoder.setComputePipelineState(pipelineState)
    }
}
