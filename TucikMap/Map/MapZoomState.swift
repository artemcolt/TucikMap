//
//  MapState.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import simd

class MapZoomState {
    
    private(set) var zoomLevelFloat: Float = 0
    private(set) var zoomLevel: Int = 0
    private(set) var tileSize: Float = 0
    private(set) var maxTileCoord: Int = 0
    private(set) var tilesCount: Int = 0
    private(set) var powZoomLevel: Float = 0
    private(set) var powZoomLevelDouble: Double = 0
    
    func update(zoomLevelFloat: Float, mapSize: Float) {
        self.zoomLevelFloat = zoomLevelFloat
        zoomLevel = Int(floor(zoomLevelFloat))
        powZoomLevelDouble = pow(2.0, Double(zoomLevel))
        powZoomLevel = Float(powZoomLevelDouble)
        
        tileSize = mapSize / powZoomLevel
        
        tilesCount = Int(powZoomLevel)
        maxTileCoord = tilesCount - 1
    }
}
