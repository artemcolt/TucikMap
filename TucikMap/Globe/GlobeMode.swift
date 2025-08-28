//
//  GlobeMode.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI
import MetalPerformanceShaders

class GlobeMode {
    struct GlobePlane {
        let verticesBuffer          : MTLBuffer
        let indicesBuffer           : MTLBuffer
        var indicesCount            : Int
        
        func isEmpty() -> Bool {
            return indicesCount == 0
        }
    }
    
    private var globeGeometryPlane      : GlobePlane
    private let metalDevice             : MTLDevice
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
    private let drawSpace               : DrawSpace
    private let drawGlobeGlowing        : DrawGlobeGlowing
    private let globeCaps               : GlobeCaps
    private let textureAdder            : TextureAdder
    private let mapSettings             : MapSettings
    private let drawMarkers             : DrawGlobeMarkers
    private let markersStorage          : MarkersStorage
    
    private var depthStencilState       : MTLDepthStencilState
    private var dsAlwaysPassState       : MTLDepthStencilState
    private var samplerState            : MTLSamplerState
    
    private var areaStateId             : UInt = 0
    private var tilesStateId            : UInt = 0
    private var generatePlaneCount      : Int = 0
    private var generateTextureCount    : Int = 0
    
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
         switchMapMode: SwitchMapMode,
         drawSpace: DrawSpace,
         drawGlobeGlowing: DrawGlobeGlowing,
         textureAdder: TextureAdder,
         mapSettings: MapSettings,
         textureLoader: TextureLoader,
         markersStorage: MarkersStorage) {
        
        self.markersStorage         = markersStorage
        self.drawGlobeLabels        = DrawGlobeLabels(screenUniforms: screenUniforms,
                                                      metalDevice: metalDevice,
                                                      camera: cameraStorage.currentView,
                                                      mapSettigns: mapSettings)
        self.textureAdder           = textureAdder
        self.drawGlobeGlowing       = drawGlobeGlowing
        self.drawSpace              = drawSpace
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
        self.mapSettings            = mapSettings
        self.drawMarkers            = DrawGlobeMarkers(metalDevice: metalDevice,
                                                       globeMarkersPipeline: pipelines.globeMarkersPipeline,
                                                       screenUnifroms: screenUniforms,
                                                       cameraStorage: cameraStorage,
                                                       textureLoader: textureLoader,
                                                       markersStorage: markersStorage)
        self.globeCaps              = GlobeCaps(metalDevice: metalDevice,
                                                mapSettings: mapSettings,
                                                cameraGlobeView: cameraStorage.globeView,
                                                mapZoomState: mapZoomState,
                                                globeCapsPipeline: pipelines.globeCapsPipeline)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        
        let dsAlwaysPassDescriptor = MTLDepthStencilDescriptor()
        dsAlwaysPassDescriptor.depthCompareFunction = .always
        dsAlwaysPassDescriptor.isDepthWriteEnabled = false
        dsAlwaysPassState = metalDevice.makeDepthStencilState(descriptor: dsAlwaysPassDescriptor)!
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDescriptor)!
        
        
        // Create globe geometry
        let newPlane = globeGeometry.createPlane(segments: 200)
        var vertices = newPlane.vertices
        var indices  = newPlane.indices
        
        let verticesBuffer = metalDevice.makeBuffer(bytes: &vertices,length: MemoryLayout<GlobePipeline.Vertex>.stride * vertices.count)!
        let indicesBuffer  = metalDevice.makeBuffer(bytes: &indices, length: MemoryLayout<UInt32>.stride * indices.count)!
        
        globeGeometryPlane = GlobePlane(verticesBuffer: verticesBuffer,
                                        indicesBuffer: indicesBuffer,
                                        indicesCount: newPlane.indices.count)
    }
    
    
    func draw(in view: MTKView, renderPassWrapper: RenderPassWrapper) {
        let assembledMap    = mapUpdater.assembledMap
        let areaRange       = assembledMap.areaRange
        let metalTiles      = assembledMap.tiles
        let currentFbIndex  = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer  = updateBufferedUniform.getCurrentFrameBuffer()
        let panX            = Float(camera.mapPanning.x)
        let uShiftMap       = panX
        
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        if assembledMap.isAreaStateChanged(compareId: areaStateId) {
            generatePlaneCount = maxBuffersInFlight
            areaStateId = assembledMap.setAreaId
        }
        
        if assembledMap.isTilesStateChanged(compareId: tilesStateId) {
            generateTextureCount = maxBuffersInFlight
            tilesStateId = assembledMap.setTilesId
        }
        
        if generateTextureCount > 0 {
            globeTexturing.render(commandBuffer: renderPassWrapper.commandBuffer,
                                  metalTiles: metalTiles,
                                  areaRange: areaRange,
                                  currentFbIndex: currentFbIndex)
            
            generateTextureCount -= 1
        }
        
        let globeRadius     = camera.globeRadius
        let transition      = switchMapMode.transition
        let verticesBuffer  = globeGeometryPlane.verticesBuffer
        let indicesBuffer   = globeGeometryPlane.indicesBuffer
        let indicesCount    = globeGeometryPlane.indicesCount
        
        if globeGeometryPlane.isEmpty() == false {
            
            // Рисуем окружение планеты
            let renderEncoderSpace = renderPassWrapper.createSpaceEnvEncoder()
            pipelines.spacePipeline.selectPipeline(renderEncoder: renderEncoderSpace)
            drawSpace.draw(renderEncoder: renderEncoderSpace,
                           uniformsBuffer: uniformsBuffer,
                           mapParams: DrawSpace.MapParams(latitude: camera.latitude, longitude: camera.longitude, scale: mapZoomState.powZoomLevel))
            renderEncoderSpace.endEncoding()
            
            
            
            let renderEncoder = renderPassWrapper.createGlobeEncoder()
            renderEncoder.setDepthStencilState(depthStencilState)
            renderEncoder.setCullMode(.front)
            
            // рисуем крышки глобуса
            globeCaps.drawCapsFor(renderEncoder: renderEncoder, uniformsBuffer: uniformsBuffer)
            
            let tilesCount = mapZoomState.tilesCount
            
            let startTexV = Float(areaRange.minY) / Float(tilesCount)
            let endTexV = (Float(areaRange.maxY) + 1) / Float(tilesCount)
            
            let startTexU = Float(areaRange.startX) / Float(tilesCount)
            let endTexU = (Float(areaRange.endX) + 1) / Float(tilesCount)
            var startAndEndUV = SIMD4<Float>(startTexU, endTexU, startTexV, endTexV)
            if areaRange.isFullMap {
                startAndEndUV = SIMD4<Float>(0, 1, 0, 1)
            }
            
            
            var globeParams = GlobePipeline.GlobeParams(globeRotation: camera.latitude,
                                                        uShift: uShiftMap,
                                                        globeRadius: globeRadius,
                                                        transition: transition,
                                                        startAndEndUV: startAndEndUV)
            
            pipelines.globePipeline.selectPipeline(renderEncoder: renderEncoder)
            renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
            renderEncoder.setVertexBytes(&globeParams, length: MemoryLayout<GlobePipeline.GlobeParams>.stride, index: 2)
            renderEncoder.setFragmentTexture(globeTexturing.getCurrentTexture(fbIndex: currentFbIndex), index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: indicesCount,
                                                indexType: .uint32,
                                                indexBuffer: indicesBuffer,
                                                indexBufferOffset: 0)
            
            renderEncoder.setDepthStencilState(dsAlwaysPassState)
            pipelines.globeLabelsPipeline.selectPipeline(renderEncoder: renderEncoder)
            drawGlobeLabels.draw(
                renderEncoder: renderEncoder,
                uniformsBuffer: uniformsBuffer,
                geoLabels: assembledMap.tileGeoLabels,
                currentFBIndex: currentFbIndex,
                globeRadius: globeRadius,
                transition: transition
            )
            
//            drawMarkers.drawMarkers(renderEncoder: renderEncoder, uniformsBuffer: uniformsBuffer)
            
            if mapSettings.getMapDebugSettings().getDrawBaseDebug() == true {
                pipelines.texturePipeline.selectPipeline(renderEncoder: renderEncoder)
                drawTexture.draw(textureEncoder: renderEncoder, texture: globeTexturing.getCurrentTexture(fbIndex: currentFbIndex), sideWidth: 500)
                pipelines.basePipeline.selectPipeline(renderEncoder: renderEncoder)
                drawTexture.drawBorders(textureEncoder: renderEncoder, sideWidth: 500)
            }
            
            renderEncoder.endEncoding()
        }
    }
}
