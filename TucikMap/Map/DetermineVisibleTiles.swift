//
//  DetermineVisibleTiles.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import simd

class DetermineVisibleTiles {
    // Настройки количества видимых тайлов по горизонтали и вертикали
    let visibleTilesX: Int = Settings.visibleTilesX
    let visibleTilesY: Int = Settings.visibleTilesY
    let mapSize = Settings.mapSize
    private let mapZoomState: MapZoomState
    private let camera: Camera
    
    init(mapZoomState: MapZoomState, camera: Camera) {
        self.mapZoomState = mapZoomState
        self.camera = camera
    }
    
    func determine() -> DetVisTilesResult {
        let centerTileX = Int(camera.centerTileX)
        let centerTileY = Int(camera.centerTileY)
        let maxTileCoord = mapZoomState.maxTileCoord
        let zoomLevel = mapZoomState.zoomLevel
        
        // Определяем диапазон видимых тайлов
        let halfTilesX = visibleTilesX / 2
        let halfTilesY = visibleTilesY / 2
        
        var visibleTiles: [Tile] = []
        // Перебираем все видимые тайлы
        for tileX in (centerTileX - halfTilesX)...(centerTileX + halfTilesX) {
            for tileY in (centerTileY - halfTilesY)...(centerTileY + halfTilesY) {
                let skip = tileX < 0 || tileY < 0 || tileX > maxTileCoord || tileY > maxTileCoord
                if skip {continue}
                
                // Добавляем тайл с текущим уровнем зума
                visibleTiles.append(Tile(x: tileX, y: tileY, z: zoomLevel))
            }
        }
        
        return DetVisTilesResult(
            visibleTiles: visibleTiles
        )
    }
}
