import Foundation

class MemoryMetalTileCache {
    private let cache: NSCache<NSString, MetalTile>
    private let cacheGeoLabels: NSCache<NSString, MetalGeoLabels>
    private let cacheRoadLabels: NSCache<NSString, MetalRoadLabels>
    
    init(maxCacheSizeInBytes: Int) {
        self.cache = NSCache<NSString, MetalTile>()
        self.cache.totalCostLimit = maxCacheSizeInBytes
        
        self.cacheGeoLabels = NSCache<NSString, MetalGeoLabels>()
        self.cacheGeoLabels.totalCostLimit = 100
        
        self.cacheRoadLabels = NSCache<NSString, MetalRoadLabels>()
        self.cacheRoadLabels.totalCostLimit = 100
    }
    
    func setTileData(tile: MetalTile, tileLabels: MetalGeoLabels, roadLabels: MetalRoadLabels, forKey key: String) {
        var estimatedCost = estimateTileByteSize(tile)
        cache.setObject(tile, forKey: key as NSString, cost: estimatedCost)
        
        cacheGeoLabels.setObject(tileLabels, forKey: key as NSString, cost: 1)
        
        cacheRoadLabels.setObject(roadLabels, forKey: key as NSString, cost: 1)
    }
    
    func getTile(forKey key: String) -> MetalTile? {
        return cache.object(forKey: key as NSString)
    }
    
    func getTileGeoLabels(forKey key: String) -> MetalGeoLabels? {
        return cacheGeoLabels.object(forKey: key as NSString)
    }
    
    func getTileRoadLabels(forKey key: String) -> MetalRoadLabels? {
        return cacheRoadLabels.object(forKey: key as NSString)
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
