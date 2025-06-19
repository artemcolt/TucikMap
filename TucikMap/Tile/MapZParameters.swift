//
//  TileTranslation.swift
//  TucikMap
//
//  Created by Artem on 6/17/25.
//

import Foundation

class MapZParameters {
    let zoomFactor: Float
    let lastTileCoord: Int
    let tileSize: Float
    let scaleX: Float
    let scaleY: Float
    
    init(z: Int) {
        let mapSize = Float(Settings.mapSize)
        
        zoomFactor = pow(2.0, Float(z))
        lastTileCoord = Int(zoomFactor) - 1
        tileSize = mapSize / zoomFactor
        scaleX = tileSize / 2.0
        scaleY = tileSize / 2.0
    }
}
