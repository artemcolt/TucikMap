//
//  GetTile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit

class GetTile {
    private let tileDownloader: TileDownloader!
    private let determineFeatureStyle: DetermineFeatureStyle!
    private let tileParser: TileMvtParser!
    private let device: MTLDevice
    private var parsedTileCache: [String: ParsedTile] = [:]
    
    private var cacheDispatchQueue: DispatchQueue = DispatchQueue(label: "com.tucikMap.parsedTilesCache", qos: .userInteractive)

    init(determineFeatureStyle: DetermineFeatureStyle, device: MTLDevice) {
        self.tileDownloader = TileDownloader()
        self.determineFeatureStyle = determineFeatureStyle
        self.device = device
        self.tileParser = TileMvtParser(device: device, determineFeatureStyle: determineFeatureStyle)
    }
    
    func getTile(request: TileRequest) -> ParsedTile? {
        let tile = request.tile
        let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
        
        // Synchronously check cache for parsed tile
        let cachedParsedTile = cacheDispatchQueue.sync {
            return parsedTileCache[tileKey]
        }
        
        if let cachedParsedTile = cachedParsedTile {
            return cachedParsedTile
        }
        
        // Get tile data from TileDownloader
        guard let tileData = tileDownloader.getOrFetch(
            request: request,
            fetched: Fetched(fetched: { newTile in
                let req = newTile.request
                let tile = req.tile
                let parsedTile = self.tileParser.parse(zoom: tile.z, x: tile.x, y: tile.y, mvtData: newTile.data)
                self.cacheDispatchQueue.async(execute: {
                    // Parse the tile data
                    let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
                    self.parsedTileCache[tileKey] = parsedTile
                    req.networkReady(newTile)
                })

            })
        ) else {
            // Tile is being downloaded asynchronously, return nil
            return nil
        }
        
        let parsedTile = self.tileParser.parse(zoom: tile.z, x: tile.x, y: tile.y, mvtData: tileData)
        
        // Store parsed tile in memory cache
        cacheDispatchQueue.async(execute: {
            // Parse the tile data
            self.parsedTileCache[tileKey] = parsedTile
        })
        
        return parsedTile
    }
}
