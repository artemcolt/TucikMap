//
//  AssembledMapKeeper.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import GISTools


class AssembledMapUpdater {
    private var mapZoomState: MapZoomState!
    private var determineVisibleTiles: DetermineVisibleTiles!
    private var determineFeatureStyle: DetermineFeatureStyle!
    private var visibleTilesResult: DetVisTilesResult!
    private var textTools: TextTools!
    private var savedView: MTKView!
    private var metalTilesStorage: MetalTilesStorage!
    private var drawingFrameRequester: DrawingFrameRequester!
    private var frameCounter: FrameCounter!
    private var screenCollisionsDetector: ScreenCollisionsDetector!
    private var mapCadDisplayLoop: MapCADisplayLoop
    private var mapModeStorage: MapModeStorage
    
    var assembledMap: AssembledMap = AssembledMap(
        tiles: [],
        tileGeoLabels: [],
        roadLabels: []
    )
    var assembledTileTitles: DrawTextData?
    
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        camera: CameraFlatView,
        textTools: TextTools,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        metalTilesStorage: MetalTilesStorage,
        screenCollisionsDetector: ScreenCollisionsDetector,
        mapCadDisplayLoop: MapCADisplayLoop,
        mapModeStorage: MapModeStorage
    ) {
        self.mapZoomState               = mapZoomState
        self.textTools                  = textTools
        self.drawingFrameRequester      = drawingFrameRequester
        self.frameCounter               = frameCounter
        self.metalTilesStorage          = metalTilesStorage
        self.screenCollisionsDetector   = screenCollisionsDetector
        self.mapCadDisplayLoop          = mapCadDisplayLoop
        self.mapModeStorage             = mapModeStorage
        determineVisibleTiles           = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        
        metalTilesStorage.addHandler(handler: onMetalingTileEnd)
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        if mapModeStorage.mapMode == .flat {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        savedView = view
        visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        guard visibleTiles.isEmpty == false else { return }
        
        var replacements = Set<MetalTile>()
        var actual = Set<MetalTile>()
        let actualZ = visibleTiles[0].z
        for i in 0..<visibleTiles.count {
            let tile = visibleTiles[i]
            
            // current visible tile is ready
            if let metalTile = metalTilesStorage.getMetalTile(tile: tile) {
                actual.insert(metalTile)
                continue
            }
            
            // find replacement for actual
            for scTile in assembledMap.tiles {
                if scTile.tile.covers(tile) || tile.covers(scTile.tile) {
                    replacements.insert(scTile)
                }
            }
            
            // don't try to fetch unavailbale tiles
            if useOnlyCached { continue }
            
            metalTilesStorage.requestMetalTile(tile: tile)
        }
        let replsArray = replacements.sorted {
            abs($0.tile.z - actualZ) > abs($1.tile.z - actualZ)
        }
        let fullMetalTilesArray = replsArray + actual
        self.assembledMap.tiles = fullMetalTilesArray
        
        
        let allReady = actual.count == visibleTiles.count
        if allReady {
            screenCollisionsDetector.newState(actualTiles: Array(actual), view: view)
            mapCadDisplayLoop.forceUpdateStates()
        }
        
        if (Settings.debugAssemblingMap) {
            print("Assembling map, replacements: \(replacements.count), tilesToRender: \(actual.count)")
        }
        
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
    }
}
