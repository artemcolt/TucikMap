//
//  GlobeMode.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class GlobeMode {
    struct GlobePlane {
        let verticesBuffer          : MTLBuffer
        let indicesBuffer           : MTLBuffer
        var indicesCount            : Int
        var globeWidthFactor        : Float
        var globeHeightFactor       : Float
        
        func isEmpty() -> Bool {
            return indicesCount == 0
        }
    }
    
    private var planesBuffered          : [GlobePlane] = []
    
    private var metalDevice             : MTLDevice
    private var globeTexturing          : GlobeTexturing
    private var metalTilesStorage       : MetalTilesStorage
    private var pipelines               : Pipelines
    private var camera                  : CameraGlobeView!
    private let updateBufferedUniform   : UpdateBufferedUniform
    private let mapZoomState            : MapZoomState
    private let globeGeometry           : GlobeGeometry
    private let screenUniforms          : ScreenUniforms
    private let drawTexture             : DrawTexture
    private let mapUpdater              : MapUpdaterGlobe
    private let switchMapMode           : SwitchMapMode
    private let drawGlobeLabels         : DrawGlobeLabels
    
    private var depthStencilState       : MTLDepthStencilState
    private var samplerState            : MTLSamplerState
    
    private var areaStateId             : UInt = 0
    private var tilesStateId            : UInt = 0
    private var generatePlaneCount      : Int = 0
    private var generateTextureCount    : Int = 0
    
    private let maxGeomVerticesCount    : Int = 10_000
    private let maxGeomIndicesCount     : Int = 40_000
    
    
    init(metalDevice: MTLDevice,
         pipelines: Pipelines,
         metalTilesStorage: MetalTilesStorage,
         cameraStorage: CameraStorage,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop,
         updateBufferedUniform: UpdateBufferedUniform,
         globeTexturing: GlobeTexturing,
         screenUniforms: ScreenUniforms,
         mapUpdater: MapUpdaterGlobe,
         switchMapMode: SwitchMapMode) {
        
        self.drawGlobeLabels        = DrawGlobeLabels(screenUniforms: screenUniforms,
                                                      metalDevice: metalDevice,
                                                      camera: cameraStorage.currentView)
        self.switchMapMode          = switchMapMode
        self.drawTexture            = DrawTexture(screenUniforms: screenUniforms)
        self.screenUniforms         = screenUniforms
        self.globeGeometry          = GlobeGeometry()
        self.mapZoomState           = mapZoomState
        self.metalDevice            = metalDevice
        self.globeTexturing         = globeTexturing
        self.camera                 = cameraStorage.globeView
        self.updateBufferedUniform  = updateBufferedUniform
        self.metalTilesStorage      = metalTilesStorage
        self.pipelines              = pipelines
        self.mapUpdater             = mapUpdater
        
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
        
        for _ in 0..<Settings.maxBuffersInFlight {
            // TODO адаптировать размеры буфферов
            let verticesBuffer = metalDevice.makeBuffer(length: MemoryLayout<GlobePipeline.Vertex>.stride * maxGeomVerticesCount)!
            let indicesBuffer  = metalDevice.makeBuffer(length: MemoryLayout<UInt32>.stride * maxGeomIndicesCount)!
            planesBuffered.append(GlobePlane(
                verticesBuffer: verticesBuffer,
                indicesBuffer: indicesBuffer,
                indicesCount: 0,
                globeWidthFactor: 0,
                globeHeightFactor: 0))
        }
    }
    
    func changePlane(bufferIndex: Int, segments: Int, areaRange: AreaRange) {
        let newPlane = globeGeometry.createPlane(segments: segments, areaRange: areaRange)
        let vertices = newPlane.vertices
        let indices  = newPlane.indices
        
        planesBuffered[bufferIndex].verticesBuffer.contents().copyMemory(from: vertices,
                                                      byteCount: MemoryLayout<GlobePipeline.Vertex>.stride * vertices.count)
        planesBuffered[bufferIndex].indicesBuffer.contents().copyMemory(from: indices,
                                                     byteCount: MemoryLayout<UInt32>.stride * indices.count)
        planesBuffered[bufferIndex].indicesCount = newPlane.indices.count
    }
    
    func draw(in view: MTKView,
              renderPassDescriptor: MTLRenderPassDescriptor,
              commandBuffer: MTLCommandBuffer) {
        
        let assembledMap    = mapUpdater.assembledMap
        let areaRange       = assembledMap.areaRange
        let metalTiles      = assembledMap.tiles
        let currentFbIndex  = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer  = updateBufferedUniform.getCurrentFrameBuffer()
        let z               = areaRange.z
        
        let tilesCount = mapZoomState.tilesCount
        let panX = Float(camera.mapPanning.x)
        
        var uShiftMap = panX
        if z > 1 {
            let uTileSize = Float(1.0 / 3.0)
            let halfTilesCount = Float(tilesCount) / 2.0
            let uShift = (panX * 2.0) * halfTilesCount * uTileSize
            uShiftMap = uTileSize - uTileSize / 2 + uShift.truncatingRemainder(dividingBy: uTileSize)
            if uShift > 0 {
                uShiftMap -= uTileSize
            }
        }
        
        if assembledMap.isAreaStateChanged(compareId: areaStateId) {
            generatePlaneCount = Settings.maxBuffersInFlight
            areaStateId = assembledMap.setAreaId
        }
        
        if assembledMap.isTilesStateChanged(compareId: tilesStateId) {
            generateTextureCount = Settings.maxBuffersInFlight
            tilesStateId = assembledMap.setTilesId
        }
        
        if generatePlaneCount > 0 {
            // TODO segments сколько выставлять
            changePlane(bufferIndex: currentFbIndex, segments: 80, areaRange: areaRange)
            generatePlaneCount -= 1
        }
        
        if generateTextureCount > 0 {
            globeTexturing.render(currentFBIndex: currentFbIndex,
                                  commandBuffer: commandBuffer,
                                  metalTiles: metalTiles,
                                  areaRange: areaRange)
            generateTextureCount -= 1
        }
        
        let globeRadius     = camera.globeRadius
        let transition      = switchMapMode.transition
        var globeParams     = GlobePipeline.GlobeParams(globeRotation: camera.latitude,
                                                        uShift: uShiftMap,
                                                        globeRadius: globeRadius,
                                                        transition: transition)
        
        let buffered        = planesBuffered[currentFbIndex]
        let texture         = globeTexturing.getTexture(frameBufferIndex: currentFbIndex)
        let verticesBuffer  = buffered.verticesBuffer
        let indicesBuffer   = buffered.indicesBuffer
        let indicesCount    = buffered.indicesCount
        
        if buffered.isEmpty() == false {
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setCullMode(.front)
            pipelines.globePipeline.selectPipeline(renderEncoder: renderEncoder)
            renderEncoder.setDepthStencilState(depthStencilState)
            renderEncoder.setVertexBuffer(verticesBuffer,     offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformsBuffer,  offset: 0, index: 1)
            renderEncoder.setVertexBytes(&globeParams, length: MemoryLayout<GlobePipeline.GlobeParams>.stride, index: 2)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: indicesCount,
                                                indexType: .uint32,
                                                indexBuffer: indicesBuffer,
                                                indexBufferOffset: 0)
            renderEncoder.endEncoding()
        }
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment = nil
        renderPassDescriptor.stencilAttachment = nil
        
        // На глобусе рисуем названия стран, городов, рек, морей
        let basicRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        pipelines.globeLabelsPipeline.selectPipeline(renderEncoder: basicRenderEncoder)
        drawGlobeLabels.draw(
            renderEncoder: basicRenderEncoder,
            uniformsBuffer: uniformsBuffer,
            geoLabels: assembledMap.tileGeoLabels,
            currentFBIndex: currentFbIndex,
            globeRadius: globeRadius
        )
        basicRenderEncoder.endEncoding()
        
        
        if Settings.drawGlobeTexture {
            // draw texture
            let textureEncoder   = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            pipelines.texturePipeline.selectPipeline(renderEncoder: textureEncoder)
            drawTexture.draw(textureEncoder: textureEncoder, texture: texture, sideWidth: 500)
            pipelines.basePipeline.selectPipeline(renderEncoder: textureEncoder)
            drawTexture.drawBorders(textureEncoder: textureEncoder, sideWidth: 500)
            textureEncoder.endEncoding()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
