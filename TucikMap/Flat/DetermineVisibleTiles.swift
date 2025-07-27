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
    private let mapZoomState: MapZoomState
    private let camera: Camera
    
    init(mapZoomState: MapZoomState, camera: Camera) {
        self.mapZoomState = mapZoomState
        self.camera = camera
    }
    
    func determine() -> DetVisTilesResult {
        var visibleTiles: [Tile] = []
        if Settings.showOnlyTiles.count > 0 {
            for tile in Settings.showOnlyTiles {
                if tile.z > Settings.maxTileZoom {
                    // Если показ этого тайла невозможен из за ограничений в зуме то нужно найти родительский тайл
                    visibleTiles.append(tile.findParentTile(atZoom: Settings.maxTileZoom)!)
                } else {
                    visibleTiles.append(tile)
                }
            }
        } else {
            var centerTileX = Int(camera.centerTileX)
            var centerTileY = Int(camera.centerTileY)
            var zoomLevel = mapZoomState.zoomLevel
            if Settings.printCenterTile {
                print("centerTileX: \(centerTileX) centerTileY: \(centerTileY) zoomLevel: \(zoomLevel)")
            }
            
            if zoomLevel > Settings.maxTileZoom {
                let parent = Tile(x: centerTileX, y: centerTileY, z: zoomLevel).findParentTile(atZoom: Settings.maxTileZoom)!
                centerTileX = parent.x
                centerTileY = parent.y
                zoomLevel = parent.z
            }
            
            let powZoomLevel = pow(2.0, Float(zoomLevel))
            let tilesCount = Int(powZoomLevel)
            let maxTileCoord = tilesCount - 1
            
            // Определяем диапазон видимых тайлов
            let halfTilesX = visibleTilesX / 2
            let halfTilesY = visibleTilesY / 2
            
            // Перебираем все видимые тайлы
            for tileX in (centerTileX - halfTilesX)...(centerTileX + halfTilesX) {
                for tileY in (centerTileY - halfTilesY)...(centerTileY + halfTilesY) {
                    let skip = tileX < 0 || tileY < 0 || tileX > maxTileCoord || tileY > maxTileCoord
                    if skip {continue}
                    
                    // Добавляем тайл с текущим уровнем зума
                    let tile = Tile(x: tileX, y: tileY, z: zoomLevel)
                    if Settings.allowOnlyTiles.isEmpty {
                        visibleTiles.append(tile)
                    } else if Settings.allowOnlyTiles.contains(tile) {
                        visibleTiles.append(tile)
                    }
                }
            }
        }
        
        if Settings.printVisibleTiles {
            print(visibleTiles)
        }
        
        return DetVisTilesResult(visibleTiles: visibleTiles)
    }
}
