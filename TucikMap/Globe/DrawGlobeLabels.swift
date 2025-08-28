//
//  DrawGlobeLabels.swift
//  TucikMap
//
//  Created by Artem on 8/6/25.
//

import MetalKit

class DrawGlobeLabels {
    private let screenUniforms: ScreenUniforms
    private let sampler: MTLSamplerState
    private let metalDevice: MTLDevice
    private let camera: Camera
    private let mapSettigns: MapSettings
    
    // на всю карту общие парметры
    struct GlobeParams {
        let latitude: Float
        let longitude: Float
        let globeRadius: Float
        let transition: Float
        let planeNormal: SIMD3<Float>
    }
    
    // параметры под один тайл
    struct GlobeLabelsParams {
        let centerX: Float
        let centerY: Float
        let factor: Float
    };
    
    init(screenUniforms: ScreenUniforms, metalDevice: MTLDevice, camera: Camera, mapSettigns: MapSettings) {
        self.mapSettigns = mapSettigns
        self.screenUniforms = screenUniforms
        self.metalDevice = metalDevice
        self.camera = camera
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    func draw(
        renderEncoder: MTLRenderCommandEncoder,
        geoLabels: [MetalTile.TextLabels],
        currentFBIndex: Int,
        globeShadersParams: GlobeShadersParams
    ) {
        guard geoLabels.isEmpty == false else { return }
        
        var globeShadersParams = globeShadersParams
        let labelsFadeAnimationTimeSeconds = mapSettigns.getMapCommonSettings().getLabelsFadeAnimationTimeSeconds()
        var animationTime = labelsFadeAnimationTimeSeconds
        
        renderEncoder.setVertexBytes(&globeShadersParams, length: MemoryLayout<GlobeShadersParams>.stride, index: 8)
        renderEncoder.setVertexBytes(&animationTime, length: MemoryLayout<Float>.stride,   index: 6)
        renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer,       offset: 0, index: 4)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        for metalTile in geoLabels {
            guard let textLabels        = metalTile.textLabels else { continue }
            
            let metalDrawMapLabels      = textLabels.metalDrawMapLabels
            let vertexBuffer            = metalDrawMapLabels.vertexBuffer
            let verticesCount           = metalDrawMapLabels.verticesCount
            let mapLabelSymbolMeta      = metalDrawMapLabels.mapLabelSymbolMeta
            let mapLabelGpuMeta         = metalDrawMapLabels.mapLabelGpuMeta
            let intersectionsBuffer     = metalDrawMapLabels.intersectionsTrippleBuffer[currentFBIndex]
            let atlasTexture            = metalDrawMapLabels.atlas
            
            renderEncoder.setVertexBuffer(vertexBuffer,         offset: 0, index: 0)
            renderEncoder.setVertexBuffer(mapLabelSymbolMeta,   offset: 0, index: 2)
            renderEncoder.setVertexBuffer(mapLabelGpuMeta,      offset: 0, index: 3)
            renderEncoder.setVertexBuffer(intersectionsBuffer,  offset: 0, index: 5)
            renderEncoder.setFragmentTexture(atlasTexture, index: 0)
            
            let tile = metalTile.tile
            let centerTileX = Float(tile.x) + 0.5
            let centerTileY = Float(tile.y) + 0.5
            let z = Float(tile.z)
            let factor = 1.0 / pow(2, z)
            let tilesNum = pow(2, z)
            let centerX = -1.0 + (centerTileX / tilesNum) * 2.0
            let centerY = (1.0 - (centerTileY / tilesNum) * 2.0)
            
            var globeLabelsParams = GlobeLabelsParams(centerX: centerX,
                                                      centerY: centerY,
                                                      factor: factor)
            
            renderEncoder.setVertexBytes(&globeLabelsParams, length: MemoryLayout<GlobeLabelsParams>.stride, index: 7)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
        }
    }
}
