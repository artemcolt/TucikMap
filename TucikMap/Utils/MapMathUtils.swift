//
//  MapMathUtils.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

import Foundation
import MetalKit

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
    
    static func getTileModelMatrix(
        tile: Tile,
        mapZoomState: MapZoomState,
        pan: SIMD3<Double>
    ) -> float4x4 {
        let mapSize = Double(Settings.mapSize)
        let zoomFactor = pow(2.0, Double(tile.z - mapZoomState.zoomLevel));
        
        let tileCenterX = Double(tile.x) + 0.5;
        let tileCenterY = Double(tile.y) + 0.5;
        let tileSize = mapSize / zoomFactor;
        
        let mapFactor = pow(2.0, Double(tile.z)) * pow(2.0, Double(mapZoomState.zoomLevel - tile.z))
        let tileWorldX = tileCenterX * tileSize - mapSize / 2 * mapFactor;
        let tileWorldY = mapSize / 2 * mapFactor - tileCenterY * tileSize;
        
        
        let scaleX = tileSize / 2;
        let scaleY = tileSize / 2;
        let offsetX = tileWorldX + pan.x * mapFactor;
        let offsetY = tileWorldY + pan.y * mapFactor;
        
        var modelMatrix = MatrixUtils.createTileModelMatrix(
            scaleX: Float(scaleX),
            scaleY: Float(scaleY),
            offsetX: Float(offsetX),
            offsetY: Float(offsetY)
        )
        return modelMatrix
    }
}
