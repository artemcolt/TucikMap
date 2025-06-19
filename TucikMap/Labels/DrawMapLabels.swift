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
    let camera: Camera
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera) {
        self.metalDevice = metalDevice
        self.screenUniforms = screenUniforms
        self.camera = camera
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    func draw(
        renderEncoder: MTLRenderCommandEncoder,
        drawLabelsFinal: DrawAssembledMap.DrawLabelsFinal,
        uniforms: MTLBuffer,
    ) {
        let drawMapLabelsData = drawLabelsFinal.result.drawMapLabelsData
        let atlasTexture = drawMapLabelsData.atlas
        let vertexBuffer = drawMapLabelsData.vertexBuffer
        let verticesCount = drawMapLabelsData.verticesCount
        let mapLabelSymbolMeta = drawMapLabelsData.mapLabelSymbolMeta
        let mapLabelLineMeta = drawMapLabelsData.mapLabelLineMeta
        let intersectionsBuffer = drawMapLabelsData.intersectionsBuffer
        var animationTime = Settings.labelsFadeAnimationTimeSeconds
        
        var panDeltaForLabels = camera.mapPanning
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(mapLabelSymbolMeta, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(mapLabelLineMeta, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(uniforms, offset: 0, index: 4)
        renderEncoder.setVertexBuffer(intersectionsBuffer, offset: 0, index: 5)
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride, index: 6)
        renderEncoder.setVertexBytes(&panDeltaForLabels, length: MemoryLayout<SIMD2<Float>>.stride, index: 7)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.setFragmentTexture(atlasTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
