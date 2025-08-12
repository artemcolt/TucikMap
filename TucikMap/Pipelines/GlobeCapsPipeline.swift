//
//  GlobeCapsPipeline.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class GlobeCapsPipeline {
    var pipelineState: MTLRenderPipelineState!
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let vertexFunction = library.makeFunction(name: "globeCapsVertex")
        let fragmentFunction = library.makeFunction(name: "globeCapsFragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[1].pixelFormat = .r8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
//        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
//        pipelineDescriptor.stencilAttachmentPixelFormat = .invalid
        
        pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func selectPipeline(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
}
