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
    private var onComplete: (Data?, Tile) -> Void
    private var ongoingTasks: [String: Void] = [:]
    private let maxConcurrentFetchs: Int = Settings.maxConcurrentFetchs
    private let fifo: FIFOQueue<Tile> = FIFOQueue(capacity: Settings.fetchTilesQueueCapacity)

    init(onComplete: @escaping (Data?, Tile) -> Void) {
        self.onComplete = onComplete
        tileDiskCaching = TileDiskCaching(onComplete: onTileDiskComplete)
        tileDownloader = TileDownloader(onComplete: onTileNetworkComplete)
    }
    
    private func _onComplete(data: Data?, tile: Tile) {
        ongoingTasks.removeValue(forKey: tile.key())
        if let deqeueTile = fifo.dequeue() {
            please(tile: deqeueTile)
        }
        onComplete(data, tile)
    }
    
    private func onTileDiskComplete(data: Data?, tile: Tile) {
        if let data = data {
            if (Settings.debugAssemblingMap) {print("Fetched disk tile: \(tile.key())")}
            _onComplete(data: data, tile: tile)
            return
        }
        
        tileDownloader.download(tile: tile)
    }
    
    private func onTileNetworkComplete(data: Data?, tile: Tile) {
        if data != nil {
            if (Settings.debugAssemblingMap) {print("Fetched network tile: \(tile.key())")}
        }
        _onComplete(data: data, tile: tile)
    }
    
    func please(tile: Tile) {
        if Settings.debugAssemblingMap { print("Request tile: \(tile)") }
        
        // Check if a fetch task already exists for this tile
        if ongoingTasks[tile.key()] != nil {
            return
        }
        
        if ongoingTasks.count >= maxConcurrentFetchs {
            fifo.enqueue(tile)
            return
        }
        
        tileDiskCaching.requestDiskCached(tile: tile) // starts with disk
        ongoingTasks[tile.key()] = ()
    }
}
