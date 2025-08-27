//
//  AssembledMapKeeper.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import SwiftUI
import GISTools


class MapUpdater {
    fileprivate var mapZoomState                    : MapZoomState!
    fileprivate var determineFeatureStyle           : DetermineFeatureStyle!
    fileprivate var textTools                       : TextTools!
    fileprivate var metalTilesStorage               : MetalTilesStorage!
    fileprivate var drawingFrameRequester           : DrawingFrameRequester!
    fileprivate var frameCounter                    : FrameCounter!
    fileprivate var mapUpdaterContext               : MapUpdaterContext
    fileprivate let screenCollisionsDetector        : ScreenCollisionsDetector
    fileprivate var updateBufferedUniform           : UpdateBufferedUniform
    fileprivate var mapCadDisplayLoop               : MapCADisplayLoop
    fileprivate var metalDevice                     : MTLDevice
    fileprivate var savedView                       : MTKView!
    fileprivate var mapModeStorage                  : MapModeStorage
    fileprivate var mapSettings                     : MapSettings
    fileprivate var determineVisibleTiles           : DetermineVisibleTiles
    
    var assembledMap: AssembledMap {
        get { mapUpdaterContext.assembledMap }
    }
    
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        camera: Camera,
        textTools: TextTools,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        metalTilesStorage: MetalTilesStorage,
        mapCadDisplayLoop: MapCADisplayLoop,
        mapModeStorage: MapModeStorage,
        mapUpdaterContext: MapUpdaterContext,
        updateBufferedUniform: UpdateBufferedUniform,
        screenCollisionsDetector: ScreenCollisionsDetector,
        mapSettings: MapSettings,
        determineVisibleTiles: DetermineVisibleTiles
    ) {
        self.screenCollisionsDetector   = screenCollisionsDetector
        self.metalDevice                = device
        self.mapZoomState               = mapZoomState
        self.textTools                  = textTools
        self.drawingFrameRequester      = drawingFrameRequester
        self.frameCounter               = frameCounter
        self.metalTilesStorage          = metalTilesStorage
        self.mapCadDisplayLoop          = mapCadDisplayLoop
        self.mapModeStorage             = mapModeStorage
        self.mapUpdaterContext          = mapUpdaterContext
        self.updateBufferedUniform      = updateBufferedUniform
        self.mapSettings                = mapSettings
        self.determineVisibleTiles      = determineVisibleTiles
    }
    
    private func shouldShowLabels(visTile: VisibleTile, showLabelsOnTilesDist: Int) -> Bool {
        let tile = visTile.tile
        let fromCenter = visTile.tilesFromCenterTile
        // чтобы на полюсах показывались противоположные лейблы
        let isYMapBorder = tile.y == 0 || tile.y == mapZoomState.maxTileCoord
        let isBeyondFrame = Int(fromCenter.x) <= showLabelsOnTilesDist && Int(fromCenter.y) <= showLabelsOnTilesDist
        return isYMapBorder || isBeyondFrame
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        savedView = view
        let visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        let areaRange = visibleTilesResult.areaRange
        guard visibleTiles.isEmpty == false else { return }
        
        let showLabelsOnTilesDist = mapSettings.getMapCommonSettings().getShowLabelsOnTilesDist()
        let withLabelsVisibleTilesCount = visibleTiles.count(where: { visTile in
            return shouldShowLabels(visTile: visTile, showLabelsOnTilesDist: showLabelsOnTilesDist)
        })
        
        // тайлы для отображения поверхности
        var groundReplacementTiles = Set<MetalTile>()
        var groundActualTiles: [MetalTile] = []
        
        // тайлы для отображений гео лейблов
        var labelsActualTiles = Set<MetalTile>()
        
        let actualZ = areaRange.z
        for i in 0..<visibleTiles.count {
            let visTile = visibleTiles[i]
            let tile = visTile.tile
            
            // current visible tile is ready
            if let metalTile = metalTilesStorage.getMetalTile(tile: tile) {
                groundActualTiles.append(metalTile)
                
                if shouldShowLabels(visTile: visTile, showLabelsOnTilesDist: showLabelsOnTilesDist) {
                    labelsActualTiles.insert(metalTile)
                }
                continue
            }
            
            // find replacement for actual
            for onMapMetalTile in assembledMap.tiles {
                if onMapMetalTile.tile.covers(tile) || tile.covers(onMapMetalTile.tile) {
                    groundReplacementTiles.insert(onMapMetalTile)
                }
            }
            
            // don't try to fetch unavailbale tiles
            if useOnlyCached { continue }
            
            metalTilesStorage.requestMetalTile(tile: tile)
        }
        
        // Для отображения поверхности
        let sortedGroundReplacements = groundReplacementTiles.sorted {
            abs($0.tile.z - actualZ) > abs($1.tile.z - actualZ)
        }
        let fullGroundTiles = sortedGroundReplacements + groundActualTiles
        self.assembledMap.setNewState(tiles: fullGroundTiles, areaRange: areaRange)
        
        let labelsActualTilesList = Array(labelsActualTiles)
        let allReady = withLabelsVisibleTilesCount == labelsActualTilesList.count
        if allReady {
            screenCollisionsDetector.newState(actualTiles: labelsActualTilesList, view: view)
            mapCadDisplayLoop.forceUpdateStates()
        }
        
        
        let debugAssemblingMap = mapSettings.getMapDebugSettings().getDebugAssemblingMap()
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        if debugAssemblingMap {
            print("Assembling map, replacements: \(groundReplacementTiles.count), tilesToRender: \(groundActualTiles.count)")
        }
        
        drawingFrameRequester.renderNextNFrames(maxBuffersInFlight)
    }
}


class MapUpdaterFlat: MapUpdater {
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        camera: CameraFlatView,
        textTools: TextTools,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        metalTilesStorage: MetalTilesStorage,
        mapCadDisplayLoop: MapCADisplayLoop,
        mapModeStorage: MapModeStorage,
        mapUpdaterContext: MapUpdaterContext,
        screenCollisionsDetector: ScreenCollisionsDetector,
        updateBufferedUniform: UpdateBufferedUniform,
        mapSettings: MapSettings,
        determineVisibleTiles: DetermineVisibleTiles
    ) {
        super.init(mapZoomState: mapZoomState,
                   device: device,
                   camera: camera,
                   textTools: textTools,
                   drawingFrameRequester: drawingFrameRequester,
                   frameCounter: frameCounter,
                   metalTilesStorage: metalTilesStorage,
                   mapCadDisplayLoop: mapCadDisplayLoop,
                   mapModeStorage: mapModeStorage,
                   mapUpdaterContext: mapUpdaterContext,
                   updateBufferedUniform: updateBufferedUniform,
                   screenCollisionsDetector: screenCollisionsDetector,
                   mapSettings: mapSettings,
                   determineVisibleTiles: determineVisibleTiles)
        
        metalTilesStorage.addHandler(handler: onMetalingTileEnd)
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        if mapModeStorage.mapMode == .flat {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
}


class MapUpdaterGlobe: MapUpdater {
    private let globeTexturing: GlobeTexturing
    
    init(mapZoomState: MapZoomState,
         device: MTLDevice,
         camera: Camera,
         textTools: TextTools,
         drawingFrameRequester: DrawingFrameRequester,
         frameCounter: FrameCounter,
         metalTilesStorage: MetalTilesStorage,
         mapCadDisplayLoop: MapCADisplayLoop,
         mapModeStorage: MapModeStorage,
         mapUpdaterContext: MapUpdaterContext,
         screenCollisionsDetector: ScreenCollisionsDetector,
         updateBufferedUniform: UpdateBufferedUniform,
         globeTexturing: GlobeTexturing,
         mapSettings: MapSettings,
         determineVisibleTiles: DetermineVisibleTiles) {
        self.globeTexturing = globeTexturing
        super.init(mapZoomState: mapZoomState,
                   device: device,
                   camera: camera,
                   textTools: textTools,
                   drawingFrameRequester: drawingFrameRequester,
                   frameCounter: frameCounter,
                   metalTilesStorage: metalTilesStorage,
                   mapCadDisplayLoop: mapCadDisplayLoop,
                   mapModeStorage: mapModeStorage,
                   mapUpdaterContext: mapUpdaterContext,
                   updateBufferedUniform: updateBufferedUniform,
                   screenCollisionsDetector: screenCollisionsDetector,
                   mapSettings: mapSettings,
                   determineVisibleTiles: determineVisibleTiles)
        
        metalTilesStorage.addHandler(handler: onMetalingTileEnd)
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        if mapModeStorage.mapMode == .globe {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
}
