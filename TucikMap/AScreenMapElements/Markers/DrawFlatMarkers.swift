//
//  DrawFlatMarkers.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class DrawFlatMarkers {
    private let metalDevice: MTLDevice
    private let markersPipeline: MarkersPipeline
    private let screenUnifroms: ScreenUniforms
    private let textureLoader: TextureLoader
    private let mapZoomState: MapZoomState
    private let markersStorage: MarkersStorage
    
    private let cameraStorage: CameraStorage
    private let sampler: MTLSamplerState
    
    
    init(metalDevice: MTLDevice,
         markersPipeline: MarkersPipeline,
         screenUnifroms: ScreenUniforms,
         cameraStorage: CameraStorage,
         textureLoader: TextureLoader,
         mapZoomState: MapZoomState,
         markersStorage: MarkersStorage) {
        self.markersStorage = markersStorage
        self.metalDevice = metalDevice
        self.markersPipeline = markersPipeline
        self.screenUnifroms = screenUnifroms
        self.cameraStorage = cameraStorage
        self.textureLoader = textureLoader
        self.mapZoomState = mapZoomState
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    
    func drawMarkers(renderEncoder: MTLRenderCommandEncoder,
                     uniformsBuffer: MTLBuffer) {
        let markersBuffer = markersStorage.markersFlatBuffer
        let markersMetaBuffer = markersStorage.markersMetaFlatBuffer
        let verticesCount = markersStorage.verticesCountFlat
        
        markersPipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(markersBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(screenUnifroms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(markersMetaBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 3)
        
        let flatMapSize = Double(cameraStorage.flatView.mapSize)
        let camera = cameraStorage.flatView
        let mapPan = camera.mapPanning
        let mapPan2 = SIMD2<Double>(mapPan.x, mapPan.y)
        var positions: [SIMD2<Float>] = []
        for marker in markersStorage.markers {
            let latLonDegrees = marker.latLonDegrees
            let markerPan = MapMathUtils.getPanByLatLonDegrees(mapSize: flatMapSize, lat: latLonDegrees.x, lon: latLonDegrees.y)
            let difference = (mapPan2 - markerPan) * mapZoomState.powZoomLevelDouble
            positions.append(SIMD2<Float>(difference))
        }
        renderEncoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 4)
        
        
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        renderEncoder.setFragmentTexture(markersStorage.textureAtlas.atlasTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
