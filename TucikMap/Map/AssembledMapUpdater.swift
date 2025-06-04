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
    private let tileMapAssembler: TileMapAssembler!
    private let tileTitleAssembler: TileTitlesAssembler!
    private var visibleTilesResult: DetVisTilesResult!
    private let assembleMapQueue = DispatchQueue(label: "com.tucikMap.assembleMapQueue")
    private var lastUpdateWorkItem: DispatchWorkItem?
    private let textTools: TextTools
    private let camera: Camera
    private let tilesResolver: TilesResolver
    
    var assembledMap: AssembledMap = AssembledMap.void()
    var assembledTileTitles: DrawTextData?
    
    
    init(mapZoomState: MapZoomState, device: MTLDevice, camera: Camera, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        self.camera = camera
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        tilesResolver = TilesResolver(getTile: GetTile(determineFeatureStyle: determineFeatureStyle, device: device))
        tileMapAssembler = TileMapAssembler(device: device, mapSize: Settings.mapSize, determineFeatureStyle: determineFeatureStyle)
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
    }
    
    private func onNewTile(newTile: NewTile) {
        assembleMapQueue.async { [weak self] in
            guard let self = self else { return }
            let request = newTile.request
            if self.visibleTilesResult.containsTile(tile: request.tile) {
                if (Settings.assemblingMapDebug) {print("On new tile network update call")}
                self.update(view: request.view)
            }
        }
    }
    
    func update(view: MTKView) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if (Settings.assemblingMapDebug) {print("Call assembling z:\(mapZoomState.zoomLevel) x:\(camera.centerTileX) y:\(camera.centerTileY)")}
            self.visibleTilesResult = self.determineVisibleTiles.determine()
            let visibleTiles = self.visibleTilesResult.visibleTiles
            let tilesToAssemble = self.tilesResolver.resolveTiles(request: ResolveTileRequest(
                view: view,
                networkReady: onNewTile,
                tiles: visibleTiles
            ))
            let assembledMap = self.tileMapAssembler.assemble(parsedTiles: tilesToAssemble)
            
            let tileTitleOffset = Settings.tileTitleOffset / mapZoomState.powZoomLevel
            if Settings.drawTileCoordinates {
                let tileTitles = self.tileTitleAssembler.assemble(
                    tiles: visibleTiles,
                    font: textTools.font,
                    scale: Settings.tileTitleRootSize / mapZoomState.powZoomLevel,
                    offset: SIMD2<Float>(tileTitleOffset, tileTitleOffset)
                )
                DispatchQueue.main.async { [weak self] in
                    self?.assembledTileTitles = tileTitles
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.assembledMap = assembledMap
                view.setNeedsDisplay()
            }
        }
        
        if let lastUpdateWorkItem = lastUpdateWorkItem {
            lastUpdateWorkItem.cancel() // if work executed then nothing happens on cancel()
        }
        
        lastUpdateWorkItem = workItem
        assembleMapQueue.async(execute: workItem)
    }
}
