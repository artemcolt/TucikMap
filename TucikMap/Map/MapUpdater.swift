//
//  AssembledMapKeeper.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import GISTools


class MapUpdater {
    private var mapZoomState            : MapZoomState!
    private var determineVisibleTiles   : DetermineVisibleTiles!
    private var determineFeatureStyle   : DetermineFeatureStyle!
    private var textTools               : TextTools!
    private var metalTilesStorage       : MetalTilesStorage!
    private var drawingFrameRequester   : DrawingFrameRequester!
    private var frameCounter            : FrameCounter!
    private var mapUpdaterContext       : MapUpdaterContext
    var updateBufferedUniform           : UpdateBufferedUniform
    var mapCadDisplayLoop               : MapCADisplayLoop
    var metalDevice                     : MTLDevice
    var savedView                       : MTKView!
    var mapModeStorage                  : MapModeStorage
    
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
    ) {
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
        determineVisibleTiles           = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        savedView = view
        let visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        let areaRange = visibleTilesResult.areaRange
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
        let fullMetalTilesArray     = replsArray + actual
        self.assembledMap.setNewState(tiles: fullMetalTilesArray, areaRange: areaRange)
        
        updateActions(view: view,
                      actual: actual,
                      visibleTilesResult: visibleTilesResult)
        
        if (Settings.debugAssemblingMap) {
            print("Assembling map, replacements: \(replacements.count), tilesToRender: \(actual.count)")
        }
        
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
    }
    
    func updateActions(view: MTKView, actual: Set<MetalTile>, visibleTilesResult: DetVisTilesResult) {
        
    }
}
