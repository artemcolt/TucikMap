//
//  ComputeScreenGlobePipeline.swift
//  TucikMap
//
//  Created by Artem on 8/8/25.
//

import MetalKit

class CompScreenGlobePipe {
    struct Parmeters {
        let latitude: Float
        let longitude: Float
        let globeRadius: Float
        let centerX: Float
        let centerY: Float
        let factor: Float
    }
    
    private(set) var pipelineState: MTLComputePipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let kernel = library.makeFunction(name: "computeScreensGlobe")!
        
        pipelineState = try! metalDevice.makeComputePipelineState(function: kernel)
    }
    
    func selectComputePipeline(computeEncoder: MTLComputeCommandEncoder) {
        computeEncoder.setComputePipelineState(pipelineState)
    }
}
