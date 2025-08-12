//
//  GlobeGeomPipeline.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class GlobeGeomPipeline {
    let pipelineState: MTLRenderPipelineState
    
    struct VertexIn {
        let position: SIMD3<Float>
    }
    
    struct MapParams {
        let globeRadius: Float
        let factor: Float
        let latitude: Float
    };
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        let vertexFunction = library.makeFunction(name: "globeGeomVertex")
        let fragmentFunction = library.makeFunction(name: "globeGeomFragment")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<VertexIn>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.stencilAttachmentPixelFormat = .invalid
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        self.pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func selectPipeline(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
}
