//
//  TexturePipeline.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit

class TexturePipeline {
    struct Vertex {
        let position: SIMD2<Float>
        let texCoord: SIMD2<Float>
    }
    
    let pipelineState: MTLRenderPipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let vertexFunction = library.makeFunction(name: "vertexShaderTexture")
        let fragmentFunction = library.makeFunction(name: "fragmentShaderTexture")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.stencilAttachmentPixelFormat = .invalid
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        self.pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func selectPipeline(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
}
