//
//  PostProcessing.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class DrawTextureOnScreen {
    private let quadVertices: [DrawTextureOnScreenPipeline.QuadVertex] = [
        DrawTextureOnScreenPipeline.QuadVertex(position: SIMD4(-1, -1, 0, 1), texCoord: SIMD2(0, 1)),
        DrawTextureOnScreenPipeline.QuadVertex(position: SIMD4(1, -1, 0, 1), texCoord: SIMD2(1, 1)),
        DrawTextureOnScreenPipeline.QuadVertex(position: SIMD4(-1, 1, 0, 1), texCoord: SIMD2(0, 0)),
        DrawTextureOnScreenPipeline.QuadVertex(position: SIMD4(1, 1, 0, 1), texCoord: SIMD2(1, 0))
    ]
    private let verticesBuffer: MTLBuffer
    private let drawTextureOnScreenPipeline: DrawTextureOnScreenPipeline
    
    init(metalDevice: MTLDevice, postProcessingPipeline: DrawTextureOnScreenPipeline) {
        verticesBuffer = metalDevice.makeBuffer(bytes: quadVertices,
                                                length: MemoryLayout<DrawTextureOnScreenPipeline.QuadVertex>.stride * quadVertices.count)!
        self.drawTextureOnScreenPipeline = postProcessingPipeline
    }
    
    func draw(currentRenderPassDescriptor: MTLRenderPassDescriptor?,
              commandBuffer: MTLCommandBuffer,
              sceneTexture: MTLTexture) {
        guard let outputPassDescriptor = currentRenderPassDescriptor else { return }
        outputPassDescriptor.depthAttachment = nil
        outputPassDescriptor.stencilAttachment = nil
        
        let outputEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: outputPassDescriptor)!
        drawTextureOnScreenPipeline.selectPipeline(renderEncoder: outputEncoder)
        outputEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        outputEncoder.setFragmentTexture(sceneTexture, index: 0)
        outputEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: quadVertices.count)
        outputEncoder.endEncoding()
    }
}
