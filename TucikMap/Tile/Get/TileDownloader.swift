//
//  TileDownloader.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import Foundation

class TileDownloader {
    private let baseURLString = "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2"
    private let accessToken = "pk.eyJ1IjoiaW52ZWN0eXMiLCJhIjoiY2w0emRzYWx5MG1iMzNlbW91eWRwZzdldCJ9.EAByLTrB_zc7-ytI6GDGBw"
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
        let tileURL = tileURLFor(zoom: zoom, x: x, y: y)
        let session: URLSession = URLSession(configuration: configuration)
        if let response = try? await session.data(from: tileURL) {
            if debugAssemblingMap { print("Tile is downloaded \(tile)") }
            return response.0
        }
        
        if debugAssemblingMap { print("Downloading tile failed \(tile)") }
        return nil
    }
    
    private func tileURLFor(zoom: Int, x: Int, y: Int) -> URL {
        let urlString = "\(baseURLString)/\(zoom)/\(x)/\(y).mvt?access_token=\(accessToken)"
        return URL(string: urlString)!
    }
}
