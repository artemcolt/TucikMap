//
//  TextPipeline.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class TextPipeline {
    var pipelineState: MTLRenderPipelineState!
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        // Настройка дескриптора вершин
        let vertexDescriptor = MTLVertexDescriptor()
        // Атрибут позиции (vector_float2 position)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<vector_float2>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        // Макет буфера вершин
        vertexDescriptor.layouts[0].stride = MemoryLayout<TextVertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        
        // Настройка дескриптора пайплайна
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "textVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "textFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
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
