//
//  AssembledMapKeeper.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit

class AssembledMapUpdater {
    private let mapZoomState: MapZoomState!
    private let determineVisibleTiles: DetermineVisibleTiles!
    private let determineFeatureStyle: DetermineFeatureStyle!
    private let tileMapAssembler: TileMapAssembler!
    private let tileTitleAssembler: TileTitlesAssembler!
    private let getTile: GetTile!
    private var visibleTilesResult: DetVisTilesResult!
    private let assembleMapQueue = DispatchQueue(label: "com.tucikMap.assembleMapQueue")
    private var lastUpdateWorkItem: DispatchWorkItem?
    private let textTools: TextTools
    
    var assembledMap: AssembledMap = AssembledMap.void()
    var assembledTileTitles: DrawTextData?
    
    
    init(mapZoomState: MapZoomState, device: MTLDevice, camera: Camera, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.textTools = textTools
        determineFeatureStyle = DetermineFeatureStyle()
        determineVisibleTiles = DetermineVisibleTiles(mapZoomState: mapZoomState, camera: camera)
        getTile = GetTile(determineFeatureStyle: determineFeatureStyle, device: device)
        tileMapAssembler = TileMapAssembler(device: device, mapSize: Settings.mapSize, determineFeatureStyle: determineFeatureStyle)
        tileTitleAssembler = TileTitlesAssembler(textAssembler: textTools.textAssembler)
    }
    
    private func onNewTile(newTile: NewTile) {
        assembleMapQueue.async { [weak self] in
            guard let self = self else { return }
            let request = newTile.request
            if self.visibleTilesResult.containsTile(tile: request.tile) {
                self.update(view: request.view, force: true)
            }
        }
    }
    
    func update(view: MTKView, force: Bool = false) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.visibleTilesResult = self.determineVisibleTiles.determine()
            let visibleTiles = self.visibleTilesResult.visibleTiles
            var tileToAssemble: [ParsedTile] = []
            for visibleTile in visibleTiles {
                guard let parsedTile = self.getTile.getTile(
                    request: TileRequest(
                        tile: visibleTile,
                        view: view,
                        networkReady: onNewTile)
                ) else {continue}
                tileToAssemble.append(parsedTile)
            }
            let assembledMap = self.tileMapAssembler.assemble(parsedTiles: tileToAssemble)
            
            let tileTitleOffset = Settings.tileTitleOffset / mapZoomState.powZoomLevel
            let tileTitles = self.tileTitleAssembler.assemble(
                tiles: visibleTiles,
                font: textTools.font,
                scale: Settings.tileTitleRootSize / mapZoomState.powZoomLevel,
                offset: SIMD2<Float>(tileTitleOffset, tileTitleOffset)
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.assembledMap = assembledMap
                self?.assembledTileTitles = tileTitles
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
