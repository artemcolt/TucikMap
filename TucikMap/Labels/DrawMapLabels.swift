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

struct MapLabelLineCollisionsMeta {
    let measuredText: MeasuredText
    let scale: simd_float1
    let localPosition: SIMD2<Float>
    let sortRank: ushort
    let id: UInt
}

struct MapLabelLineMeta {
    let measuredText: MeasuredText
    let scale: simd_float1
    let localPosition: SIMD2<Float>
}

struct LabelIntersection {
    let hide: Bool
    let createdTime: Float
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
        geoLabels: [MetalGeoLabels],
        uniformsBuffer: MTLBuffer,
        currentFBIndex: Int,
        tileModelMatrices: TileModelMatrices
    ) {
        guard geoLabels.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        var animationTime = Settings.labelsFadeAnimationTimeSeconds
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride, index: 6)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 4)
        
        let mapPanning = camera.mapPanning
        for tile in geoLabels {
            guard let textLabels = tile.textLabels else { continue }
            var modelMatrix = tileModelMatrices.get(tile: tile.tile)
            
            let drawMapLabelsData = textLabels.drawMapLabelsData
            let vertexBuffer = drawMapLabelsData.vertexBuffer
            let verticesCount = drawMapLabelsData.verticesCount
            let mapLabelSymbolMeta = drawMapLabelsData.mapLabelSymbolMeta
            let mapLabelLineMeta = drawMapLabelsData.mapLabelLineMeta
            let intersectionsBuffer = drawMapLabelsData.intersectionsTrippleBuffer[currentFBIndex]
            let atlasTexture = drawMapLabelsData.atlas
            
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(mapLabelSymbolMeta, offset: 0, index: 2)
            renderEncoder.setVertexBuffer(mapLabelLineMeta, offset: 0, index: 3)
            renderEncoder.setVertexBuffer(intersectionsBuffer, offset: 0, index: 5)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 7)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
        }
    }
}
