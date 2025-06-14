//
//  DrawMapLabels.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

import MetalKit

struct MapLabelSymbolMeta {
    let lineMetaIndex: simd_int1
}

struct MapLabelLineMeta {
    let measuredText: MeasuredText
    let scale: simd_float1
    let worldPosition: SIMD2<Float>
}

class DrawMapLabels {
    let metalDevice: MTLDevice
    let sampler: MTLSamplerState
    var orthographicProjectionMatrix: matrix_float4x4!
    var screenUniforms: ScreenUniforms
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms) {
        self.metalDevice = metalDevice
        self.screenUniforms = screenUniforms
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    func draw(
        renderEncoder: MTLRenderCommandEncoder,
        drawMapLabelsData: DrawMapLabelsData,
        uniforms: MTLBuffer,
    ) {
        let atlasTexture = drawMapLabelsData.atlas
        let vertexBuffer = drawMapLabelsData.vertexBuffer
        let verticesCount = drawMapLabelsData.verticesCount
        let mapLabelSymbolMeta = drawMapLabelsData.mapLabelSymbolMeta
        let mapLabelLineMeta = drawMapLabelsData.mapLabelLineMeta
        let intersectionsBuffer = drawMapLabelsData.intersectionsBuffer
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(mapLabelSymbolMeta, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(mapLabelLineMeta, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(uniforms, offset: 0, index: 4)
        renderEncoder.setVertexBuffer(intersectionsBuffer, offset: 0, index: 5)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.setFragmentTexture(atlasTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
