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
    static func getTilePositionTranslate(
        tile: Tile,
        mapZoomState: MapZoomState,
        pan: SIMD3<Double>
    ) -> TilePositionTranslate {
        let mapSize = Double(Settings.flatMapSize)
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
        pan: SIMD3<Double>
    ) -> float4x4 {
        let tileTranslation = getTilePositionTranslate(tile: tile, mapZoomState: mapZoomState, pan: pan)
        return MatrixUtils.createTileModelMatrix(
            scaleX: tileTranslation.scaleX,
            scaleY: tileTranslation.scaleY,
            scaleZ: tileTranslation.scaleZ,
            offsetX: tileTranslation.offsetX,
            offsetY: tileTranslation.offsetY
        )
    }
}
