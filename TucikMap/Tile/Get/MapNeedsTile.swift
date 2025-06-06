//
//  GetTile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import GISTools

class MapNeedsTile {
    private var tileDownloader: TileDownloader!
    private var tileDiskCaching: TileDiskCaching!
    private var onComplete: (Data, Tile) -> Void

    init(onComplete: @escaping (Data, Tile) -> Void) {
        self.onComplete = onComplete
        tileDiskCaching = TileDiskCaching(onComplete: onTileDiskComplete)
        tileDownloader = TileDownloader(onComplete: onTileNetworkComplete)
    }
    
    private func onTileDiskComplete(data: Data?, tile: Tile) {
        if let data = data {
            if (Settings.debugAssemblingMap) {print("Fetched disk tile: \(tile.key())")}
            onComplete(data, tile)
            return
        }
        
        tileDownloader.download(tile: tile)
    }
    
    private func onTileNetworkComplete(data: Data?, tile: Tile) {
        guard let data = data else { return }
        if (Settings.debugAssemblingMap) {print("Fetched network tile: \(tile.key())")}
        onComplete(data, tile)
    }
    
    func please(tile: Tile) {
        if Settings.debugAssemblingMap { print("Request tile: \(tile)") }
        tileDiskCaching.requestDiskCached(tile: tile) // starts with disk
    }
}
