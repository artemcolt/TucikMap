//
//  GlobeMode.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class GlobeMode {
    private var globeTexturing          : GlobeTexturing
    private var globeBuffer             : MTLBuffer
    private var metalTilesStorage       : MetalTilesStorage
    private var pipelines               : Pipelines
    private var camera                  : CameraGlobeView!
    private let updateBufferedUniform   : UpdateBufferedUniform
    
    private var globeVerticesCount      : Int
    private var depthStencilState       : MTLDepthStencilState
    private var samplerState            : MTLSamplerState
    
    init(metalDevice: MTLDevice,
         pipelines: Pipelines,
         metalTilesStorage: MetalTilesStorage,
         cameraStorage: CameraStorage,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop,
         updateBufferedUniform: UpdateBufferedUniform,
         globeTexturing: GlobeTexturing) {
        
        self.globeTexturing = globeTexturing
        
        let vertices = GlobeGeometry().createPlane(segments: 40)
        globeBuffer = metalDevice.makeBuffer(bytes: vertices, length: MemoryLayout<GlobePipeline.Vertex>.stride * vertices.count)!
        globeVerticesCount = vertices.count
        
        self.updateBufferedUniform = updateBufferedUniform
        self.metalTilesStorage = metalTilesStorage
        self.pipelines = pipelines
        
        camera = cameraStorage.globeView
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
        
        
        metalTilesStorage.requestMetalTile(tile: Tile(x: 0, y: 0, z: 0))
    }
    
    func draw(in view: MTKView,
              renderPassDescriptor: MTLRenderPassDescriptor,
              commandBuffer: MTLCommandBuffer) {
        
        let currentFbIndex = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer  = updateBufferedUniform.getCurrentFrameBuffer()
        var globeParams     = GlobePipeline.GlobeParams(globeRotation: camera.globeRotation,
                                                       uShift: camera.uShift,
                                                       globeRadius: camera.globeRadius)

        globeTexturing.updateTexture(currentFBIndex: currentFbIndex,
                                     commandBuffer: commandBuffer)
        
        let renderEncoder   = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        let texture         = globeTexturing.getTexture(frameBufferIndex: currentFbIndex)
        renderEncoder.setCullMode(.front)
        pipelines.globePipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(globeBuffer,     offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer,  offset: 0, index: 1)
        renderEncoder.setVertexBytes(&globeParams, length: MemoryLayout<GlobePipeline.GlobeParams>.stride, index: 2)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: globeVerticesCount)
        renderEncoder.endEncoding()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
