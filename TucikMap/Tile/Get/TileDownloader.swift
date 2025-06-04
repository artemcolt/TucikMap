//
//  TileDownloader.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import Foundation

class TileDownloader {
    private let cacheDirectory: URL
    private let cacheDuration: TimeInterval = 7 * 24 * 60 * 60 // 1 week in seconds
    private let baseURLString = "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2"
    private let accessToken = "pk.eyJ1IjoiaW52ZWN0eXMiLCJhIjoiY2w0emRzYWx5MG1iMzNlbW91eWRwZzdldCJ9.EAByLTrB_zc7-ytI6GDGBw"
    private let session: URLSession
    private var ongoingTasks: [String: URLSessionDataTask] = [:]

    init() {
        // Initialize cache directory
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("MapTiles")
        
        // Create cache directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create cache directory: \(error)")
        }
        
        let config = URLSessionConfiguration.default
        config.tlsMaximumSupportedProtocolVersion = .TLSv12
        session = URLSession(configuration: config)
        
        if Settings.clearDownloadedOnDiskTiles {
            do {
                try clearAllCache()
            } catch {
                print("Failed to clear cache: \(error)")
            }
        }
    }
    
    func getCached(tile: Tile) -> Data? {
        let zoom = tile.z
        let x = tile.x
        let y = tile.y
        let cachePath = cachePathFor(zoom: zoom, x: x, y: y)
        return loadCachedTile(at: cachePath)
    }
    
    func download(request: TileRequest, fetched: Fetched) {
        let zoom = request.tile.z
        let x = request.tile.x
        let y = request.tile.y
        let tileKey = "\(zoom)_\(x)_\(y)"
        
        // Check if a download task already exists for this tile
        if ongoingTasks[tileKey] != nil {
            return
        }
        
        // Create new download task
        let tileURL = tileURLFor(zoom: zoom, x: x, y: y)
        let task = session.dataTask(with: tileURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data, error == nil {
                // Save to cache if download is successful
                let cachePath = cachePathFor(zoom: zoom, x: x, y: y)
                self.saveToCache(data: data, for: cachePath)
                fetched.fetched(NewTile(data: data, request: request))
            } else if let error = error {
                print("Failed to download tile \(tileKey): \(error)")
            }
            
            // Clean up
            self.ongoingTasks[tileKey] = nil
            //print("Tile loaded zoom:\(zoom) x:\(x) y:\(y)")
        }
        
        // Store and start the task
        ongoingTasks[tileKey] = task
        task.resume()
    }
    
    func clearAllCache() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
            print("MapTiles cache directory removed successfully.")
        } else {
            print("MapTiles cache directory does not exist.")
        }
        // Recreate the cache directory after clearing
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            print("MapTiles cache directory recreated successfully.")
        } catch {
            print("Failed to recreate cache directory: \(error)")
            throw error
        }
    }
    
    private func tileURLFor(zoom: Int, x: Int, y: Int) -> URL {
        let urlString = "\(baseURLString)/\(zoom)/\(x)/\(y).mvt?access_token=\(accessToken)"
        return URL(string: urlString)!
    }
    
    private func cachePathFor(zoom: Int, x: Int, y: Int) -> URL {
        let fileName = "\(zoom)_\(x)_\(y).mvt"
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    private func loadCachedTile(at cachePath: URL) -> Data? {
        let fileManager = FileManager.default
        
        // Check if tile exists
        guard fileManager.fileExists(atPath: cachePath.path) else {
            //print("Tile not found at: \(cachePath.path)")
            return nil
        }
        
        // Check tile age using modification date
        guard let attributes = try? fileManager.attributesOfItem(atPath: cachePath.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            print("Failed to read attributes for tile at: \(cachePath.path)")
            return nil
        }
        
        let currentDate = Date()
        if currentDate.timeIntervalSince(modificationDate) > cacheDuration {
            // Tile is outdated, remove it
            try? fileManager.removeItem(at: cachePath)
            print("Removed outdated tile at: \(cachePath.path)")
            return nil
        }
        
        // Load tile data
        do {
            let data = try Data(contentsOf: cachePath)
            //print("Loaded cached tile from: \(cachePath.path)")
            return data
        } catch {
            print("Failed to load tile data from \(cachePath.path): \(error)")
            return nil
        }
    }
    
    private func saveToCache(data: Data, for cachePath: URL) {
        let fileManager = FileManager.default
        let directory = cachePath.deletingLastPathComponent()
        
        // Ensure the cache directory exists
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create cache directory \(directory.path): \(error)")
            return
        }
        
        do {
            // Save tile data
            try data.write(to: cachePath, options: .atomic)
            //print("Saved tile to: \(cachePath.path)")
        } catch {
            print("Failed to save tile to \(cachePath.path): \(error)")
        }
    }
}
