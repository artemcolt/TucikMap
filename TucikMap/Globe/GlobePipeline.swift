//
//  GlobePipeline.swift
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

import MetalKit

class GlobePipeline {
    struct Vertex {
        let position: SIMD2<Float>
        let planeCoord: SIMD2<Float>
    }
    
    struct GlobeParams {
        let globeRotation   : Float
        let uShift          : Float
        let globeRadius     : Float
    }
    
    let pipelineState: MTLRenderPipelineState
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let vertexFunction = library.makeFunction(name: "vertexShaderGlobe")
        let fragmentFunction = library.makeFunction(name: "fragmentShaderGlobe")
        
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
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        self.pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func selectPipeline(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
}
