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
    private let maxConcurrentFetchs: Int = Settings.maxConcurrentFetchs
    private let fifo: FIFOQueue<Tile> = FIFOQueue(capacity: Settings.fetchTilesQueueCapacity)
    
    init(onComplete: @escaping (Data?, Tile) -> Void) {
        self.onComplete = onComplete
        
        tileDiskCaching = TileDiskCaching()
        tileDownloader = TileDownloader()
    }
    
    func please(tile: Tile) {
        if ongoingTasks[tile.key()] != nil {
            if Settings.debugAssemblingMap { print("Requested already tile \(tile)") }
            return
        }
        
        if ongoingTasks.count >= maxConcurrentFetchs {
            fifo.enqueue(tile)
            if Settings.debugAssemblingMap { print("Request fifo enque tile \(tile)") }
            return
        }
        
        if Settings.debugAssemblingMap { print("Request tile \(tile)") }
        let task = Task {
            if Settings.enabledThrottling { try? await Task.sleep(nanoseconds: UInt64.random(in: 0...Settings.throttlingNanoSeconds))}
            if let data = await tileDiskCaching.requestDiskCached(tile: tile) {
                if (Settings.debugAssemblingMap) {print("Fetched disk tile: \(tile.key())")}
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
