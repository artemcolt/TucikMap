//
//  TextureAdder.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class TextureAdder {
    private let metalDevice: MTLDevice
    private let textureAdderPipeline: TextureAdderPipeline
    
    init(metalDevice: MTLDevice, textureAdderPipeline: TextureAdderPipeline) {
        self.metalDevice = metalDevice
        self.textureAdderPipeline = textureAdderPipeline
    }
    
    func addTextures(sceneTex: MTLTexture,
                     bluredTex: MTLTexture,
                     maskedTex: MTLTexture,
                     outTexture: MTLTexture,
                     commandBuffer: MTLCommandBuffer) {
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        textureAdderPipeline.selectPipeline(computeEncoder: computeEncoder)
        computeEncoder.setTexture(sceneTex, index: 0)
        computeEncoder.setTexture(bluredTex, index: 1)
        computeEncoder.setTexture(maskedTex, index: 2)
        computeEncoder.setTexture(outTexture, index: 3)
        
        // Dispatch threads
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (sceneTex.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (sceneTex.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
    }
}
