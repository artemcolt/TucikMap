//
//  MapMathUtils.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

import Foundation
import MetalKit



struct TilePositionTranslate {
    let scaleX: Float
    let scaleY: Float
    let scaleZ: Float
    let offsetX: Float
    let offsetY: Float
}

class MapMathUtils {
    static func normalizeCoord(coord: Int, z: Int) -> Int {
        let n = 1 << z
        var normalized = coord % n
        if normalized < 0 {
            normalized += n
        }
        return normalized
    }
    
    static func normalizeLatLonDegrees(latLon: SIMD2<Double>) -> SIMD2<Double> {
        return SIMD2<Double>(latLon.x / 90, latLon.y / 180)
    }
    
    static func degreesToRadians(degrees: SIMD2<Double>) -> SIMD2<Double> {
        return degrees * .pi / 180.0
    }
    
    static func latitudeDegreesToNormalized(latitudeDegrees: Double) -> Double {
        let latRad = latitudeDegrees * .pi / 180.0
        let mercY = log(tan(.pi / 4.0 + latRad / 2.0))
        return mercY / .pi
    }
    
    static func longitudeDegreesToNormalized(longitudeDegrees: Double) -> Double {
        return longitudeDegrees / 180.0
    }
    
    static func getPanByLatLonDegrees(mapSize: Double, lat: Double, lon: Double) -> SIMD2<Double> {
        // Step 1: Convert longitude to Mercator x
        let x = (lon + 180.0) / 360.0 * mapSize
        
        // Step 2: Convert latitude to Mercator y
        let latRad = -lat * .pi / 180.0
        let mercY = log(tan(.pi / 4 + latRad / 2.0))
        let y = mapSize * (0.5 - mercY / (2 * .pi))
        
        // Step 3: Apply map offsets to get panX and panY
        let panX = mapSize / 2.0 - x
        let panY = mapSize / 2.0 - y
        
        return SIMD2<Double>(panX, panY)
    }
    
    static func getLatLonDegreesByPan(mapSize: Double, panX: Double, panY: Double) -> SIMD2<Double> {
        // Step 1: Reverse the map offset to get Mercator coordinates x and y
        let x = mapSize / 2 - panX
        let y = mapSize / 2 - panY
        
        // Step 2: Convert Mercator x to longitude
        let lon = (x / mapSize * 360.0) - 180.0
        
        // Step 3: Convert Mercator y to latitude
        let latRad = 2.0 * (atan(exp(.pi * (1.0 - 2.0 * y / mapSize))) - .pi / 4)
        let lat = -latRad * 180.0 / .pi
        
        return SIMD2<Double>(lat, lon)
    }
    
    static func getTilePositionTranslate(
        tile: Tile,
        mapZoomState: MapZoomState,
        pan: SIMD3<Double>,
        mapSize: Float
    ) -> TilePositionTranslate {
        let mapSize = Double(mapSize)
        let zoomFactor = pow(2.0, Double(tile.z - mapZoomState.zoomLevel));
        
        let tileCenterX = Double(tile.x) + 0.5;
        let tileCenterY = Double(tile.y) + 0.5;
        let tileSize = mapSize / zoomFactor;
        
        let mapFactor = pow(2.0, Double(tile.z)) * pow(2.0, Double(mapZoomState.zoomLevel - tile.z))
        let tileWorldX = tileCenterX * tileSize - mapSize / 2 * mapFactor;
        let tileWorldY = mapSize / 2 * mapFactor - tileCenterY * tileSize;
        
        
        let scaleX = tileSize / 2;
        let scaleY = tileSize / 2;
        let scaleZ = tileSize / 2;
        let offsetX = tileWorldX + pan.x * mapFactor;
        let offsetY = tileWorldY + pan.y * mapFactor;
        return TilePositionTranslate(
            scaleX: Float(scaleX),
            scaleY: Float(scaleY),
            scaleZ: Float(scaleZ),
            offsetX: Float(offsetX),
            offsetY: Float(offsetY)
        )
    }
    
    static func getTileModelMatrix(
        tile: Tile,
        mapZoomState: MapZoomState,
        pan: SIMD3<Double>,
        mapSize: Float
    ) -> float4x4 {
        let tileTranslation = getTilePositionTranslate(tile: tile, mapZoomState: mapZoomState, pan: pan, mapSize: mapSize)
        return MatrixUtils.createTileModelMatrix(
            scaleX: tileTranslation.scaleX,
            scaleY: tileTranslation.scaleY,
            scaleZ: tileTranslation.scaleZ,
            offsetX: tileTranslation.offsetX,
            offsetY: tileTranslation.offsetY
        )
    }
}
