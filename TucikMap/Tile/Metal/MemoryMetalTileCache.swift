import Foundation

class MemoryMetalTileCache {
    private let cache: NSCache<NSString, MetalTile>
    
    init(maxCacheSizeInBytes: Int) {
        self.cache = NSCache<NSString, MetalTile>()
        self.cache.totalCostLimit = maxCacheSizeInBytes
    }
    
    func setTileData(tile: MetalTile, forKey key: String) {
        let estimatedCost = estimateTileByteSize(tile)
        cache.setObject(tile, forKey: key as NSString, cost: estimatedCost)
    }
    
    func getTile(forKey key: String) -> MetalTile? {
        return cache.object(forKey: key as NSString)
    }
    
    private func estimateTileByteSize(_ tile: MetalTile) -> Int {
        let tile2dBuffers = tile.tile2dBuffers
        let tile3dBuffers = tile.tile3dBuffers
        
        // Estimate size based on buffer lengths
        let verticesSize = tile2dBuffers.verticesBuffer.allocatedSize + (tile3dBuffers.verticesBuffer?.allocatedSize ?? 0)
        let indicesSize = tile2dBuffers.indicesBuffer.allocatedSize + (tile3dBuffers.indicesBuffer?.allocatedSize ?? 0)
        let stylesSize = tile2dBuffers.stylesBuffer.allocatedSize + (tile3dBuffers.stylesBuffer?.allocatedSize ?? 0)
        return verticesSize + indicesSize + stylesSize
    }
}
