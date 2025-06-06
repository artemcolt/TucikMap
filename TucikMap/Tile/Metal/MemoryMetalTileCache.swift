//
//  MemoryMetalTileCache.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import Foundation

class MemoryMetalTileCache {
    private let cache: NSCache<NSString, MetalTile>
    
    /// Initializes the cache with optional limits for object count and total memory.
    /// - Parameters:
    ///   - countLimit: Maximum number of tiles to store (default: 100).
    ///   - totalCostLimit: Maximum memory size in bytes (default: 50 MB).
    init(countLimit: Int = Settings.maxCachedTilesCount, totalCostLimit: Int = Settings.maxCachedTilesMemory) {
        self.cache = NSCache<NSString, MetalTile>()
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    /// Adds a MetalTile to the cache with the specified key.
    /// - Parameters:
    ///   - tile: The MetalTile object to cache.
    ///   - key: The string key to associate with the tile.
    func setTile(_ tile: MetalTile, forKey key: String) {
        let cost = calculateTileMemoryCost(tile)
        cache.setObject(tile, forKey: key as NSString, cost: cost)
    }
    
    /// Retrieves a MetalTile from the cache for the specified key.
    /// - Parameter key: The string key associated with the tile.
    /// - Returns: The cached MetalTile, or nil if not found.
    func tile(forKey key: String) -> MetalTile? {
        return cache.object(forKey: key as NSString)
    }
    
    /// Checks if a tile exists in the cache for the specified key.
    /// - Parameter key: The string key to check.
    /// - Returns: True if a tile exists for the key, false otherwise.
    func containsTile(forKey key: String) -> Bool {
        return cache.object(forKey: key as NSString) != nil
    }
    
    /// Removes a MetalTile from the cache for the specified key.
    /// - Parameter key: The string key associated with the tile.
    func removeTile(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Removes all MetalTiles from the cache.
    func removeAllTiles() {
        cache.removeAllObjects()
    }
    
    /// Updates the cache limits.
    /// - Parameters:
    ///   - countLimit: Maximum number of tiles to store.
    ///   - totalCostLimit: Maximum memory size in bytes.
    func updateCacheLimits(countLimit: Int, totalCostLimit: Int) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }
    
    /// Calculates the approximate memory cost of a MetalTile based on its buffers.
    /// - Parameter tile: The MetalTile to evaluate.
    /// - Returns: The estimated memory size in bytes.
    private func calculateTileMemoryCost(_ tile: MetalTile) -> Int {
        let vertexSize = tile.verticesBuffer.allocatedSize
        let indicesSize = tile.indicesBuffer.allocatedSize
        let stylesSize = tile.stylesBuffer.allocatedSize
        let modelMatrixSize = tile.modelMatrixBuffer.allocatedSize
        return vertexSize + indicesSize + stylesSize + modelMatrixSize
    }
}
