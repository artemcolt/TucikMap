//
//  DrawText.swift
//  TucikMap
//
//  Created by Artem on 6/1/25.
//
import MetalKit

class DrawText {
    let metalDevice: MTLDevice
    var sampler: MTLSamplerState!
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func renderText(
        renderEncoder: MTLRenderCommandEncoder,
        uniforms: MTLBuffer,
        drawTextData: DrawTextData
    ) {
        let atlasTexture = drawTextData.atlas
        let vertexBuffer = drawTextData.vertexBuffer
        let glyphBuffer = drawTextData.glyphPropBuffer
        let verticesCount = drawTextData.verticesCount
        
        renderEncoder.setVertexBuffer(uniforms, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(glyphBuffer, offset: 0, index: 2)

        renderEncoder.setFragmentTexture(atlasTexture, index: 0)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
    
    func renderTextBytes(
        renderEncoder: MTLRenderCommandEncoder,
        uniforms: MTLBuffer,
        drawTextData: DrawTextDataBytes
    ) {
        let atlasTexture = drawTextData.atlas
        let vertices = drawTextData.vertices
        let glyphProps = drawTextData.glyphProps
        let verticesCount = drawTextData.verticesCount
        
        renderEncoder.setVertexBuffer(uniforms, offset: 0, index: 1)
        renderEncoder.setVertexBytes(vertices, length: MemoryLayout<TextVertex>.size * vertices.count, index: 0)
        renderEncoder.setVertexBytes(glyphProps, length: MemoryLayout<GlyphGpuProp>.size * glyphProps.count, index: 2)

        renderEncoder.setFragmentTexture(atlasTexture, index: 0)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
