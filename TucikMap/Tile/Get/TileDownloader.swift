//
//  TileDownloader.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import Foundation

class TileDownloader {
    private let configuration: URLSessionConfiguration
    private let mapSettings: MapSettings

    init(mapSettings: MapSettings) {
        configuration = URLSessionConfiguration.default
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv12
        self.mapSettings = mapSettings
    }
    
    func download(tile: Tile) async -> Data? {
        let zoom = tile.z
        let x = tile.x
        let y = tile.y
        let tileKey = tile.key()
        let debugAssemblingMap = mapSettings.getMapDebugSettings().getDebugAssemblingMap()
        
        if debugAssemblingMap { print("Download tile \(tileKey)") }
        
        // Create new download task
        let tileURL = mapSettings.getMapCommonSettings().GetGetMapTileDownloadUrl().get(tileX: x, tileY: y, tileZ: zoom)
        let session: URLSession = URLSession(configuration: configuration)
        if let response = try? await session.data(from: tileURL) {
            if debugAssemblingMap { print("Tile is downloaded \(tile)") }
            return response.0
        }
        
        if debugAssemblingMap { print("Downloading tile failed \(tile)") }
        return nil
    }
}
