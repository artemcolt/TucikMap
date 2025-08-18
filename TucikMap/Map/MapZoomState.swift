//
//  MapState.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import simd

class MapZoomState {
    private let nullZoomCameraDistance: Float
    
    private(set) var zoomLevelFloat: Float = 0
    private(set) var zoomLevel: Int = 0
    private(set) var tileSize: Float = 0
    private(set) var maxTileCoord: Int = 0
    private(set) var tilesCount: Int = 0
    private(set) var powZoomLevel: Float = 0
    
    init(mapSettings: MapSettings) {
        nullZoomCameraDistance = mapSettings.getMapCameraSettings().getNullZoomCameraDistance()
    }
    
    func update(zoomLevelFloat: Float, mapSize: Float) {
        
        self.zoomLevelFloat = zoomLevelFloat
        zoomLevel = Int(floor(zoomLevelFloat))
        powZoomLevel = pow(2.0, Float(zoomLevel))
        
        tileSize = mapSize / powZoomLevel
        
        tilesCount = Int(powZoomLevel)
        maxTileCoord = tilesCount - 1
    }
}
