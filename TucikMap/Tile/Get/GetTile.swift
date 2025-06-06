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
    
    func fetchTile(request: TileRequest) {
        Task {
            let tile = request.tile
            if let vectorTileFromDisk = tileDownloader.getCached(tile: tile) {
                onTileFetched(newTile: NewTile(data: vectorTileFromDisk, request: request))
                return
            }
            
            // if disk cache is unavailable then download tile
            DispatchQueue.main.async {
                self.tileDownloader.download(
                    request: request,
                    fetched: Fetched(fetched: self.onTileFetched)
                )
            }
        }
    }
    
    private func onTileFetched(newTile: NewTile) {
        let req = newTile.request
        let tile = req.tile
        let parsedTile = self.tileParser.parse(tile: tile, mvtData: newTile.data, boundingBox: req.boundingBox)
        DispatchQueue.main.async {
            let tileKey = "\(tile.z)_\(tile.x)_\(tile.y)"
            self.parsedTileCache[tileKey] = parsedTile
            req.tileReady(newTile)
        }
    }
}
