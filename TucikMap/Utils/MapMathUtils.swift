//
//  MapMathUtils.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

import Foundation

class MapMathUtils {
    static func coordinatesToMapPoint(latitude: Float, longitude: Float) -> SIMD2<Float> {
        // Validate inputs
        guard latitude >= -90 && latitude <= 90 else {
            fatalError("Latitude must be between -90 and 90 degrees")
        }
        guard longitude >= -180 && longitude <= 180 else {
            fatalError("Longitude must be between -180 and 180 degrees")
        }
        
        let mapSize = Settings.mapSize
        let halfMapSize = mapSize / 2
        
        // Convert latitude to radians for Mercator projection
        let latRad = -latitude * .pi / 180.0
        
        // Mercator projection calculations
        // X is linear with longitude
        let x = (longitude + 180.0) / 360.0 * mapSize
        
        // Y uses Mercator projection formula
        let y = (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * mapSize
        
        return SIMD2<Float>(x: Float(x - halfMapSize), y: Float(y - halfMapSize))
    }
    
    struct TileTransition {
        let tileWorld: SIMD2<Float>
        let scale: SIMD2<Float>
    }
    
    static func getTileTransition(tile: Tile) -> TileTransition {
        let mapZParameters = MapZParameters(z: tile.z)
        let tileSize = mapZParameters.tileSize
        let tileCenterX = Float(tile.x) + 0.5
        let tileCenterY = Float(tile.y) + 0.5
        let tileWorldX = tileCenterX * Float(tileSize) - Float(Settings.mapSize) / 2
        let tileWorldY = Float(Settings.mapSize) / 2 - tileCenterY * Float(tileSize)
        let scale = SIMD2<Float>(mapZParameters.scaleX, mapZParameters.scaleY)
        let tileWorld = SIMD2<Float>(tileWorldX, tileWorldY)
        return TileTransition(tileWorld: tileWorld, scale: scale)
    }
}
