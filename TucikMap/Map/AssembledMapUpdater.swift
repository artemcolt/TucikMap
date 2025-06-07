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
    private var tilesResolver: TilesResolver!
    private var savedView: MTKView!
    
    var assembledMap: AssembledMap?
    var assembledTileTitles: DrawTextData?
    
    
    init(mapZoomState: MapZoomState, device: MTLDevice, camera: Camera, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        self.camera = camera
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
        tilesResolver = TilesResolver(determineStyle: determineFeatureStyle, metalDevice: device, onProcessedTiles: self.onProcessedTiles)
    }
    
    private func onProcessedTiles() {
        self.update(view: savedView, useOnlyCached: true)
    }
    
    func update(view: MTKView, useOnlyCached: Bool) {
        savedView = view
        visibleTilesResult = determineVisibleTiles.determine()
        let visibleTiles = visibleTilesResult.visibleTiles
        let resolvedTiles = tilesResolver.resolveTiles(request: ResolveTileRequest(
            visibleTiles: visibleTiles,
            useOnlyCached: useOnlyCached
        ))
        let assembledMap = AssembledMap(
            tiles: resolvedTiles.tempTiles + resolvedTiles.actualTiles,
        )
        if (Settings.debugAssemblingMap) {
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
