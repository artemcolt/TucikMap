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
    private var ongoingTasks: [String: Task<Void, Never>] = [:]
    private let maxConcurrentFetchs: Int
    private let fifo: FIFOQueue<Tile>
    private let mapSettings: MapSettings
    
    init(mapSettings: MapSettings, onComplete: @escaping (Data?, Tile) -> Void) {
        self.onComplete = onComplete
        self.maxConcurrentFetchs = mapSettings.getMapCommonSettings().getMaxConcurrentFetchs()
        self.mapSettings = mapSettings
        self.fifo = FIFOQueue(capacity: mapSettings.getMapCommonSettings().getFetchTilesQueueCapacity())
        
        tileDiskCaching = TileDiskCaching(mapSettings: mapSettings)
        tileDownloader = TileDownloader(mapSettings: mapSettings)
    }
    
    func please(tile: Tile) {
        let debugAssemblingMap = mapSettings.getMapDebugSettings().getDebugAssemblingMap()
        let enabledThrottling = mapSettings.getMapDebugSettings().getEnabledThrottling()
        let throttlingNanoSeconds = mapSettings.getMapDebugSettings().getThrottlingNanoSeconds()
        
        if ongoingTasks[tile.key()] != nil {
            if debugAssemblingMap { print("Requested already tile \(tile)") }
            return
        }
        
        if ongoingTasks.count >= maxConcurrentFetchs {
            fifo.enqueue(tile)
            if debugAssemblingMap { print("Request fifo enque tile \(tile)") }
            return
        }
        
        if debugAssemblingMap { print("Request tile \(tile)") }
        let task = Task {
            if enabledThrottling { try? await Task.sleep(nanoseconds: UInt64.random(in: 0...throttlingNanoSeconds))}
            if let data = await tileDiskCaching.requestDiskCached(tile: tile) {
                if debugAssemblingMap {print("Fetched disk tile: \(tile.key())")}
                await MainActor.run {
                    _onComplete(data: data, tile: tile)
                }
                return
            }
            
            if let data = await tileDownloader.download(tile: tile) {
                tileDiskCaching.saveOnDisk(tile: tile, data: data)
                await MainActor.run {
                    _onComplete(data: data, tile: tile)
                }
                return
            }
        }
        
        ongoingTasks[tile.key()] = task
    }
    
    private func _onComplete(data: Data?, tile: Tile) {
        ongoingTasks.removeValue(forKey: tile.key())
        if let deqeueTile = fifo.dequeue() {
            please(tile: deqeueTile)
        }
        onComplete(data, tile)
    }
}
