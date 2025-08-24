//
//  DrawMarkers.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class DrawGlobeMarkers {
    private let metalDevice: MTLDevice
    private let globeMarkersPipeline: GlobeMarkersPipeline
    private let screenUnifroms: ScreenUniforms
    private let textureLoader: TextureLoader
    private let cameraStorage: CameraStorage
    private let markersStorage: MarkersStorage
    private let sampler: MTLSamplerState
    
    
    init(metalDevice: MTLDevice,
         globeMarkersPipeline: GlobeMarkersPipeline,
         screenUnifroms: ScreenUniforms,
         cameraStorage: CameraStorage,
         textureLoader: TextureLoader,
         markersStorage: MarkersStorage) {
        self.markersStorage = markersStorage
        self.metalDevice = metalDevice
        self.globeMarkersPipeline = globeMarkersPipeline
        self.screenUnifroms = screenUnifroms
        self.cameraStorage = cameraStorage
        self.textureLoader = textureLoader
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
        
    }
    
    func drawMarkers(renderEncoder: MTLRenderCommandEncoder,
                     uniformsBuffer: MTLBuffer) {
        let markersBuffer = markersStorage.markersGlobeBuffer
        let markersMetaBuffer = markersStorage.markersMetaGlobeBuffer
        let verticesCount = markersStorage.verticesCountGlobe
        
        globeMarkersPipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setVertexBuffer(markersBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(screenUnifroms.screenUniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(markersMetaBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 3)
        
        let latitude = cameraStorage.currentView.latitude
        let longitude = cameraStorage.currentView.longitude
        let globeRadius = cameraStorage.currentView.globeRadius
        var globeParams = GlobeMarkersPipeline.GlobeParams(latitude: latitude,
                                                           longitude: longitude,
                                                           globeRadius: globeRadius)
        renderEncoder.setVertexBytes(&globeParams, length: MemoryLayout<GlobeMarkersPipeline.GlobeParams>.stride, index: 4)
        
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        renderEncoder.setFragmentTexture(markersStorage.textureAtlas.atlasTexture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
