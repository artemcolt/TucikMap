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
         metalCommandQueue: MTLCommandQueue,
         pipelines: Pipelines,
         metalTilesStorage: MetalTilesStorage,
         cameraStorage: CameraStorage,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop,
         updateBufferedUniform: UpdateBufferedUniform) {
        globeTexturing  = GlobeTexturing(metalDevide: metalDevice,
                                        metalCommandQueue: metalCommandQueue,
                                        pipelines: pipelines)
        
        let vertices = GlobeGeometry().createPlane(segments: 40)
        globeBuffer = metalDevice.makeBuffer(bytes: vertices, length: MemoryLayout<GlobePipeline.Vertex>.stride * vertices.count)!
        globeVerticesCount = vertices.count
        
        self.updateBufferedUniform = updateBufferedUniform
        self.metalTilesStorage = metalTilesStorage
        self.pipelines = pipelines
        
        camera = cameraStorage.createGlobeView()
        
        metalTilesStorage.requestMetalTile(tile: Tile(x: 0, y: 0, z: 0))
        
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
    }
    
    var testReady = false
    func draw(in view: MTKView,
              renderPassDescriptor: MTLRenderPassDescriptor,
              commandBuffer: MTLCommandBuffer) {
        
        let uniformsBuffer = updateBufferedUniform.getCurrentFrameBuffer()
        var globeParams    = GlobePipeline.GlobeParams(globeRotation: camera.globeRotation,
                                                       uShift: Float(camera.mapPanning.x))
        
        if testReady == false {
            if let tile = metalTilesStorage.getMetalTile(tile: Tile(x: 0, y: 0, z: 0)) {
                globeTexturing.render(currentFBIndex: 0, metalTiles: [tile])
                testReady = true
            }
        }

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.globePipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setDepthStencilState(depthStencilState)
        let texture = globeTexturing.getTexture(frameBufferIndex: 0)
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
