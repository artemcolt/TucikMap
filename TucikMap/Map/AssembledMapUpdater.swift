//
//  AssembledMapKeeper.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import GISTools

class AssembledMapUpdater {
    private let mapZoomState: MapZoomState!
    private let determineVisibleTiles: DetermineVisibleTiles!
    private let determineFeatureStyle: DetermineFeatureStyle!
    private let tileTitleAssembler: TileTitlesAssembler!
    private var visibleTilesResult: DetVisTilesResult!
    private let textTools: TextTools
    private let camera: Camera
    private let tilesResolver: TilesResolver
    
    var assembledMap: AssembledMap?
    var assembledTileTitles: DrawTextData?
    
    
    init(mapZoomState: MapZoomState, device: MTLDevice, camera: Camera, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        self.camera = camera
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        tilesResolver = TilesResolver(getTile: GetTile(determineFeatureStyle: determineFeatureStyle, device: device))
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
    }
    
    private func onNewTile(newTile: NewTile) {
        let request = newTile.request
        if self.visibleTilesResult.containsTile(tile: request.tile) {
            if (Settings.assemblingMapDebug) {print("On new tile update call")}
            self.update(view: request.view, useOnlyCached: true)
        }
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        let resolvedTiles = tilesResolver.resolveTiles(request: ResolveTileRequest(
            view: view,
            networkReady: onNewTile,
            tiles: visibleTiles,
            useOnlyCached: useOnlyCached
        ))
        let assembledMap = AssembledMap(
            parsedTiles: resolvedTiles.tempTiles + resolvedTiles.actualTiles,
        )
        if (Settings.assemblingMapDebug) {
            print("Assembling map, tempTiles: \(resolvedTiles.tempTiles.count), actual: \(resolvedTiles.actualTiles.count)")
        }
        
        updateTitles(visibleTiles: visibleTiles)
        
        self.assembledMap = assembledMap
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
