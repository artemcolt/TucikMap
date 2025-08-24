//
//  GlobeMarkersPipeline.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class GlobeMarkersPipeline {
    var pipelineState: MTLRenderPipelineState!
    
    struct MarkerVertex {
        let texCoord: SIMD2<Float>
    }
    
    struct MapMarkerMeta {
        let size: Float
        let globeNormalizedPosition: SIMD2<Float>
    }
    
    struct GlobeParams {
        let latitude: Float
        let longitude: Float
        let globeRadius: Float
    }
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        // Настройка дескриптора вершин
        let vertexDescriptor = MTLVertexDescriptor()
        // Атрибут позиции (vector_float2 position)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // Макет буфера вершин
        vertexDescriptor.layouts[0].stride = MemoryLayout<MarkerVertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        
        // Настройка дескриптора пайплайна
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "globeMarkersVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "globeMarkersFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.stencilAttachmentPixelFormat = .invalid
        
        // Настройка смешивания для поддержки прозрачности
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Ошибка создания пайплайна: \(error)")
        }
    }
    
    func selectPipeline(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
    }
}
