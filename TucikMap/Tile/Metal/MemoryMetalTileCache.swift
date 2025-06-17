import Foundation

class MemoryMetalTileCache {
    private let cache: NSCache<NSString, MetalTile>
    private let maxCacheSizeInBytes: Int
    
    init(maxCacheSizeInBytes: Int) {
        self.maxCacheSizeInBytes = maxCacheSizeInBytes
        self.cache = NSCache<NSString, MetalTile>()
        self.cache.totalCostLimit = maxCacheSizeInBytes
    }
    
    func setTile(_ tile: MetalTile, forKey key: String) {
        let estimatedCost = estimateTileByteSize(tile)
        cache.setObject(tile, forKey: key as NSString, cost: estimatedCost)
    }
    
    func getTile(forKey key: String) -> MetalTile? {
        return cache.object(forKey: key as NSString)
    }
    
    private func estimateTileByteSize(_ tile: MetalTile) -> Int {
        // Estimate size based on buffer lengths
        let verticesSize = tile.verticesBuffer.allocatedSize
        let indicesSize = tile.indicesBuffer.allocatedSize
        let stylesSize = tile.stylesBuffer.allocatedSize
        return verticesSize + indicesSize + stylesSize
    }
}
