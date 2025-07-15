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
    private var tileTitleAssembler: TileTitlesAssembler!
    private var visibleTilesResult: DetVisTilesResult!
    private var textTools: TextTools!
    private var camera: Camera!
    private var savedView: MTKView!
    private var metalTiles: MetalTilesStorage!
    private var renderFrameCount: RenderFrameCount!
    private var frameCounter: FrameCounter!
    
    var assembledMap: AssembledMap = AssembledMap(
        tiles: [],
        tileGeoLabels: [],
        roadLabels: []
    )
    var assembledTileTitles: DrawTextData?
    
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        camera: Camera,
        textTools: TextTools,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter,
    ) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        self.camera = camera
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
        metalTiles = MetalTilesStorage(
            determineStyle: determineFeatureStyle,
            metalDevice: device,
            textTools: textTools,
            onMetalingTileEnd: onMetalingTileEnd
        )
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        self.update(view: savedView, useOnlyCached: true)
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        savedView = view
        visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        metalTiles.setupTilesFilter(filterTiles: visibleTiles)
        
        var replacements = Set<MetalTile>()
        var actual = Set<MetalTile>()
        let actualZ = visibleTiles[0].z
        for i in 0..<visibleTiles.count {
            let tile = visibleTiles[i]
            
            // current visible tile is ready
            if let metalTile = metalTiles.getMetalTile(tile: tile) {
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
            
            metalTiles.requestMetalTile(tile: tile)
        }
        let replsArray = replacements.sorted {
            abs($0.tile.z - actualZ) > abs($1.tile.z - actualZ)
        }
        let fullMetalTilesArray = replsArray + actual
        self.assembledMap.tiles = fullMetalTilesArray
        
        
        // tile geo labels
        var allActualReady = true
        var actualGeoLabels: [MetalGeoLabels] = []
        var actualRoadLabels: [MetalRoadLabels] = []
        for i in 0..<visibleTiles.count {
            let tile = visibleTiles[i]
            
            // get actual road labels
            // get actual geo labels
            if let metalGeoLabels = metalTiles.getMetalGeoLabels(tile: tile),
               let metalRoadLabels = metalTiles.getMetalRoadLabels(tile: tile) {
                actualGeoLabels.append(metalGeoLabels)
                actualRoadLabels.append(metalRoadLabels)
                continue
            }
            
            allActualReady = false
            break
        }
        if allActualReady {
            camera.screenCollisionsDetector.handleGeoLabels.setGeoLabels(geoLabels: actualGeoLabels)
            camera.screenCollisionsDetector.setRoadLabels(roadLabelsByTiles: actualRoadLabels)
            camera.mapCadDisplayLoop.recomputeIntersections()
        }
        
        if (Settings.debugAssemblingMap) {
            print("Assembling map, replacements: \(replacements.count), tilesToRender: \(actual.count)")
        }
        
        renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight)
    }
}
