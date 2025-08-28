//
//  FlatMode.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import SwiftUI
import MetalKit

class FlatMode {
    private var metalDevice                 : MTLDevice
    private var metalCommandQueue           : MTLCommandQueue
    private var updateBufferedUniform       : UpdateBufferedUniform
    private var mapUpdaterFlat              : MapUpdaterFlat
    private var mapCadDisplayLoop           : MapCADisplayLoop
    private let draw3dBuildings             : Draw3dBuildings
    private let pipelines                   : Pipelines
    private let drawAssembledMap            : DrawAssembledMap
    private let camera                      : CameraFlatView
    private let mapZoomState                : MapZoomState
    private let mapSettings                 : MapSettings
    private let drawMarkers                 : DrawFlatMarkers
    private let markersStorage              : MarkersStorage
    private let screenUniforms              : ScreenUniforms
    private let drawUI                      : DrawUI
    private let drawDebugData               : DrawDebugData
    
    private let drawBaseDebug               : Bool
    
    // Helpers
    private let drawPoint: DrawPoint
    private var colors: [String: SIMD4<Float>] = [:]
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         frameCounter: FrameCounter,
         drawingFrameRequester: DrawingFrameRequester,
         textTools: TextTools,
         metalTilesStorage: MetalTilesStorage,
         mapCadDisplayLoop: MapCADisplayLoop,
         screenUniforms: ScreenUniforms,
         cameraStorage: CameraStorage,
         pipelines: Pipelines,
         mapZoomState: MapZoomState,
         updateBufferedUniform: UpdateBufferedUniform,
         mapModeStorage: MapModeStorage,
         drawPoint: DrawPoint,
         mapUpdaterFlat: MapUpdaterFlat,
         mapSettings: MapSettings,
         textureLoader: TextureLoader,
         markersStorage: MarkersStorage,
         drawUI: DrawUI,
         drawDebugData: DrawDebugData) {
        
        self.drawDebugData              = drawDebugData
        self.screenUniforms             = screenUniforms
        self.drawBaseDebug              = mapSettings.getMapDebugSettings().getDrawBaseDebug()
        self.markersStorage             = markersStorage
        self.mapSettings                = mapSettings
        self.drawPoint                  = drawPoint
        self.pipelines                  = pipelines
        self.metalDevice                = metalDevice
        self.metalCommandQueue          = metalCommandQueue
        self.mapCadDisplayLoop          = mapCadDisplayLoop
        self.mapZoomState               = mapZoomState
        self.updateBufferedUniform      = updateBufferedUniform
        self.mapUpdaterFlat             = mapUpdaterFlat
        self.drawUI                     = drawUI
        
        camera                      = cameraStorage.flatView
        
        drawAssembledMap            = DrawAssembledMap(metalDevice: metalDevice,
                                                       screenUniforms: screenUniforms,
                                                       camera: camera,
                                                       mapZoomState: mapZoomState,
                                                       mapSettings: mapSettings)
        
        draw3dBuildings             = Draw3dBuildings(polygon3dPipeline: pipelines.polygon3dPipeline,
                                                      drawAssembledMap: drawAssembledMap,
                                                      metalDevice: metalDevice)
        
        drawMarkers                 = DrawFlatMarkers(metalDevice: metalDevice,
                                                      markersPipeline: pipelines.markersPipeline,
                                                      screenUnifroms: screenUniforms,
                                                      cameraStorage: cameraStorage,
                                                      textureLoader: textureLoader,
                                                      mapZoomState: mapZoomState,
                                                      markersStorage: markersStorage)
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //let panningPoint = Tile(x: 9904, y: 5122, z: 14).getTilePointPanningCoordinates(normalizedX: -1, normalizedY: 0)
        //camera.moveToPanningPoint(point: panningPoint, zoom: 14, view: view, size: size)
    }
    
    func draw(in view: MTKView, renderPassWrapper: RenderPassWrapper) {
        
        let currentFBIdx            = updateBufferedUniform.getCurrentFrameBufferIndex()
        let uniformsBuffer          = updateBufferedUniform.getCurrentFrameBuffer()
        let assembledMap            = mapUpdaterFlat.assembledMap
        let assembledTiles          = assembledMap.tiles
        let areaRange               = assembledMap.areaRange
        let mapPanning              = camera.mapPanning
        let lastUniforms            = updateBufferedUniform.lastUniforms!
        let tileFrameProps          = TileFrameProps(mapZoomState: mapZoomState,
                                                     pan: mapPanning,
                                                     uniforms: lastUniforms,
                                                     areaRange: areaRange,
                                                     cameraFlatView: camera)
        
        let buildingsDepthPrepassEncoder = renderPassWrapper.createBuidingPrepassEncoder()
        buildingsDepthPrepassEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        draw3dBuildings.prepass(renderEncoder: buildingsDepthPrepassEncoder,
                                assembledTiles: assembledTiles,
                                tileFrameProps: tileFrameProps)
        buildingsDepthPrepassEncoder.endEncoding()
        
        
        let renderEncoder = renderPassWrapper.createFlatEncoder()
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        pipelines.polygonPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawAssembledMap.drawTiles(
            renderEncoder: renderEncoder,
            tiles: assembledTiles,
            areaRange: areaRange,
            tileFrameProps: tileFrameProps
        )
        
        
        pipelines.roadLabelPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawAssembledMap.drawRoadLabels(
            renderEncoder: renderEncoder,
            roadLabelsDrawing: assembledMap.roadLabels,
            currentFBIndex: currentFBIdx,
            tileFrameProps: tileFrameProps
        )
        
        
        draw3dBuildings.draw(renderEncoder: renderEncoder,
                             assembledTiles: assembledTiles,
                             tileFrameProps: tileFrameProps)
        
        
        pipelines.labelsPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawAssembledMap.drawMapLabels(
            renderEncoder: renderEncoder,
            geoLabels: assembledMap.tileGeoLabels,
            currentFBIndex: currentFBIdx,
            tileFrameProps: tileFrameProps
        )
        
//        let drawRoadPointsDebug = mapSettings.getMapDebugSettings().getDrawRoadPointsDebug()
//        if drawRoadPointsDebug {
//            drawRoadPoints(assembledMap: assembledMap,
//                           tileFrameProps: tileFrameProps,
//                           basicRenderEncoder: basicRenderEncoder,
//                           uniformsBuffer: uniformsBuffer)
//        }
        
        //drawMarkers.drawMarkers(renderEncoder: basicRenderEncoder, uniformsBuffer: uniformsBuffer)
        
        if drawBaseDebug {
            pipelines.basePipeline.selectPipeline(renderEncoder: renderEncoder)
            drawDebugData.drawGlobePoint(renderEncoder: renderEncoder)
            drawDebugData.drawAxes(renderEncoder: renderEncoder)
            
            pipelines.textPipeline.selectPipeline(renderEncoder: renderEncoder)
            renderEncoder.setVertexBuffer(screenUniforms.screenUniformBuffer, offset: 0, index: 1)
            drawUI.drawZoomUiText(renderCommandEncoder: renderEncoder, size: view.drawableSize, mapZoomState: mapZoomState)
        }
        
        renderEncoder.endEncoding()
    }
    
    private func drawRoadPoints(
        assembledMap: AssembledMap,
        tileFrameProps: TileFrameProps,
        basicRenderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer
    ) {
        for i in 0..<assembledMap.roadLabels.count {
            let tileRoadLabels = assembledMap.roadLabels[i]
            let metalRoadLabels = tileRoadLabels.metalRoadLabels
            let tile = metalRoadLabels.tile
            guard let roadLabels = metalRoadLabels.roadLabels else { continue }
            let props = tileFrameProps.get(tile: tile, loop: 0)
            let modelMatrix = props.model
            guard props.frustrumPassed else { continue }
            let metas = roadLabels.mapLabelsCpuMeta
            
            for i2 in 0..<metas.count {
                let key = "\(i)\(i2)"
                var color = colors[key]
                if color == nil {
                    let randomColor = SIMD4<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1.0)
                    colors[key] = randomColor
                    color = randomColor
                }
                
                let meta = metas[i2]
                let localPositions = meta.localPositions
                let cameraCenterPointSize = mapSettings.getMapDebugSettings().getCameraCenterPointSize()
                for point in localPositions {
                    let pointToDraw = modelMatrix * SIMD4<Float>(point.x, point.y, 0, 1)
                    drawPoint.draw(
                        renderEncoder: basicRenderEncoder,
                        uniformsBuffer: uniformsBuffer,
                        pointSize: cameraCenterPointSize * 0.5,
                        position: SIMD3<Float>(pointToDraw.x, pointToDraw.y, 0),
                        color: color!,
                    )
                }
            }
        }
    }
}
