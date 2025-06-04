//
//  GetTile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit
import GISTools

class GetTile {
    private let tileDownloader: TileDownloader!
    private let determineFeatureStyle: DetermineFeatureStyle!
    private let tileParser: TileMvtParser!
    private let device: MTLDevice
    private var parsedTileCache: [String: ParsedTile] = [:]

    init(determineFeatureStyle: DetermineFeatureStyle, device: MTLDevice) {
        self.tileDownloader = TileDownloader()
        self.determineFeatureStyle = determineFeatureStyle
        self.device = device
        self.tileParser = TileMvtParser(device: device, determineFeatureStyle: determineFeatureStyle)
    }
    
    func getCachedTile(tile: Tile) -> ParsedTile? {
        let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
        if let parsedTileCached = parsedTileCache[tileKey] {
            return parsedTileCached
        }
        
        
        return nil
    }
    
    func getTileClipped(tile: Tile, boundingBox: BoundingBox) -> ParsedTile? {
        guard let vectorTile = tileDownloader.getCached(tile: tile) else { return nil }
        let parsedTile = tileParser.parse(tile: tile, mvtData: vectorTile, boundingBox: boundingBox)
        return parsedTile
    }
    
    func fetchTile(request: TileRequest) {
        Task {
            let tile = request.tile
            let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
            if let vectorTileFromDisk = tileDownloader.getCached(tile: tile) {
                let parsedTile = tileParser.parse(tile: tile, mvtData: vectorTileFromDisk, boundingBox: TilesResolver.localTileBounds)
                DispatchQueue.main.async {
                    self.parsedTileCache[tileKey] = parsedTile
                }
            }
        }
        
        tileDownloader.download(
            request: request,
            fetched: Fetched(fetched: { newTile in
                let req = newTile.request
                let tile = req.tile
                let parsedTile = self.tileParser.parse(tile: tile, mvtData: newTile.data, boundingBox: req.boundingBox)
                DispatchQueue.main.async {
                    if req.isBoundsLocal {
                        let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
                        self.parsedTileCache[tileKey] = parsedTile
                    }
                    req.networkReady(newTile)
                }
            })
        )
    }
}
