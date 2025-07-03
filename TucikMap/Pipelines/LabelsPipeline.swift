//
//  LabelsPipeline.swift
//  TucikMap
//
//  Created by Artem on 6/9/25.
//

import MetalKit

class LabelsPipeline {
    var pipelineState: MTLRenderPipelineState!
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        // Настройка дескриптора вершин
        let vertexDescriptor = MTLVertexDescriptor()
        // Атрибут позиции (vector_float2 position)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        // Макет буфера вершин
        vertexDescriptor.layouts[0].stride = MemoryLayout<LabelsVertexIn>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        
        // Настройка дескриптора пайплайна
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "labelsVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "labelsFragmentShader")
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
