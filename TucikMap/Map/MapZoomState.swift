//
//  MapState.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import simd

class MapZoomState {
    private let nullZoomCameraDistance = Settings.nullZoomCameraDistance
    private let baseTileSize: Float = Settings.mapSize
    
    private(set) var zoomLevelFloat: Float = 0
    private(set) var zoomLevel: Int = 0
    //private(set) var mapScaleFactor: Float = 1.0
    //private(set) var powZoomLevel: Float = 0
    private(set) var tileSize: Float = 0
    private(set) var maxTileCoord: Int = 0
    private(set) var tilesCount: Int = 0
    
    func update(zoomLevelFloat: Float) {
        self.zoomLevelFloat = zoomLevelFloat
        zoomLevel = Int(floor(zoomLevelFloat))
        //mapScaleFactor = 1.0 / pow(2.0, Float(zoomLevelFloat))
        let powZoomLevel = pow(2.0, Float(zoomLevel))
        
        tileSize = baseTileSize / powZoomLevel
        tilesCount = Int(powZoomLevel)
        maxTileCoord = tilesCount - 1
    }
}
