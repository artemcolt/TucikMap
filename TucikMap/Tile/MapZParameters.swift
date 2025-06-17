//
//  TileTranslation.swift
//  TucikMap
//
//  Created by Artem on 6/17/25.
//

import Foundation

class MapZParameters {
    let zoomFactor: Double
    let lastTileCoord: Int
    let tileSize: Double
    let scaleX: Double
    let scaleY: Double
    
    init(z: Int) {
        let mapSize = Double(Settings.mapSize)
        
        zoomFactor = pow(2.0, Double(z))
        lastTileCoord = Int(zoomFactor) - 1
        tileSize = mapSize / zoomFactor
        scaleX = tileSize / 2.0
        scaleY = tileSize / 2.0
    }
}
