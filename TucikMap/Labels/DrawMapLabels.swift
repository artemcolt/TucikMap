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
    let tileIndex: simd_int1
}

class DrawMapLabels {
    let metalDevice: MTLDevice
    let sampler: MTLSamplerState
    var screenUniforms: ScreenUniforms
    let camera: Camera
    let mapZoomState: MapZoomState
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.screenUniforms = screenUniforms
        self.camera = camera
        self.mapZoomState = mapZoomState
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    func draw(
        renderEncoder: MTLRenderCommandEncoder,
        drawLabelsFinal: MapLabelsMaker.DrawLabelsFinal,
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
        
        let tiles = drawLabelsFinal.tiles
        var modelMatrices: [float4x4] = []
        for tile in tiles {
            let tileModelMatrix = MapMathUtils.getTileModelMatrix(
                tile: tile,
                mapZoomState: mapZoomState,
                pan: camera.mapPanning
            )
            modelMatrices.append(tileModelMatrix)
        }
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(mapLabelSymbolMeta, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(mapLabelLineMeta, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(uniforms, offset: 0, index: 4)
        renderEncoder.setVertexBuffer(intersectionsBuffer, offset: 0, index: 5)
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride, index: 6)
        renderEncoder.setVertexBytes(&modelMatrices, length: MemoryLayout<matrix_float4x4>.stride * modelMatrices.count, index: 7)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.setFragmentTexture(atlasTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
