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
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.tlsMaximumSupportedProtocolVersion = .TLSv12
        session = URLSession(configuration: config)
    }
    
    func download(tile: Tile) async -> Data? {
        let zoom = tile.z
        let x = tile.x
        let y = tile.y
        let tileKey = tile.key()
        
        if Settings.debugAssemblingMap { print("Download tile \(tileKey)") }
        
        // Create new download task
        let tileURL = tileURLFor(zoom: zoom, x: x, y: y)
        if let response = try? await session.data(from: tileURL) {
            if Settings.debugAssemblingMap { print("Tile is downloaded \(tile)") }
            return response.0
        }
        
        if Settings.debugAssemblingMap { print("Downloading tile failed \(tile)") }
        return nil
    }
    
    private func tileURLFor(zoom: Int, x: Int, y: Int) -> URL {
        let urlString = "\(baseURLString)/\(zoom)/\(x)/\(y).mvt?access_token=\(accessToken)"
        return URL(string: urlString)!
    }
}
