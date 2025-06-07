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
    private let onComplete: (Data, Tile) -> Void

    init(onComplete: @escaping (Data, Tile) -> Void) {
        let config = URLSessionConfiguration.default
        config.tlsMaximumSupportedProtocolVersion = .TLSv12
        session = URLSession(configuration: config)
        self.onComplete = onComplete
    }
    
    func download(tile: Tile) {
        let zoom = tile.z
        let x = tile.x
        let y = tile.y
        let tileKey = tile.key()
        
        if Settings.debugAssemblingMap { print("Download tile \(tileKey)") }
        
        // Create new download task
        let tileURL = tileURLFor(zoom: zoom, x: x, y: y)
        let task = session.dataTask(with: tileURL) { data, response, error in
            self.networkResult(data: data, response: response, error: error, tile: tile)
        }
        task.resume()
    }
    
    private func networkResult(data: Data?, response: URLResponse?, error: Error?, tile: Tile) {
        if Settings.debugAssemblingMap { print("Tile is downloaded \(tile)") }
        DispatchQueue.main.async { [weak self] in
            if let data = data, error == nil {
                self?.onComplete(data, tile)
            } else if let error = error {
                print("Failed to download tile \(error)")
            }
        }
    }
    
    private func tileURLFor(zoom: Int, x: Int, y: Int) -> URL {
        let urlString = "\(baseURLString)/\(zoom)/\(x)/\(y).mvt?access_token=\(accessToken)"
        return URL(string: urlString)!
    }
}
