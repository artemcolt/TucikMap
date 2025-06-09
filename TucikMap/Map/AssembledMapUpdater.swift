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
    
    var assembledMap: AssembledMap?
    var assembledTileTitles: DrawTextData?
    
    
    init(mapZoomState: MapZoomState, device: MTLDevice, camera: Camera, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        self.camera = camera
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
        metalTiles = MetalTilesStorage(
            determineStyle: determineFeatureStyle,
            metalDevice: device,
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
        var actual: [MetalTile] = []
        let actualZ = visibleTiles[0].z
        for i in 0..<visibleTiles.count {
            let tile = visibleTiles[i]
            
            // current visible tile is ready
            if let metalTile = metalTiles.getMetalTile(tile: tile) {
                actual.append(metalTile)
                continue
            }
            
            // find replacement for actual
            if let tiles = assembledMap?.tiles {
                for scTile in tiles {
                    if scTile.tile.covers(tile) || tile.covers(scTile.tile) {
                        replacements.insert(scTile)
                    }
                }
            }
            
            // don't try to fetch unavailbale tiles
            if useOnlyCached { continue }
            
            metalTiles.requestMetalTile(tile: tile)
        }
        
        if (Settings.debugAssemblingMap) {
            print("Assembling map, replacements: \(replacements.count), tilesToRender: \(actual.count)")
        }
        
        updateTitles(visibleTiles: visibleTiles)
        
        let replsArray = replacements.sorted {
            abs($0.tile.z - actualZ) > abs($1.tile.z - actualZ)
        }
        
        self.assembledMap = AssembledMap(tiles: replsArray + actual)
        view.setNeedsDisplay()
    }
    
    private func updateTitles(visibleTiles: [Tile]) {
        let tileTitleOffset = Settings.tileTitleOffset / mapZoomState.powZoomLevel
        if Settings.drawTileCoordinates {
            let tileTitles = self.tileTitleAssembler.assemble(
                tiles: visibleTiles,
                font: textTools.font,
                scale: Settings.tileTitleRootSize / mapZoomState.powZoomLevel,
                offset: SIMD2<Float>(tileTitleOffset, tileTitleOffset)
            )
            assembledTileTitles = tileTitles
        }
    }
}
