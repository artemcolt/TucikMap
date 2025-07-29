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
        var zoomLevel = mapZoomState.zoomLevel
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
            
            var startY = centerTileY - halfTilesY
            var endY = centerTileY + halfTilesY
            if startY < 0 {
                let shiftY = abs(startY)
                startY += shiftY
                endY += shiftY
            } else if endY > maxTileCoord {
                let shiftY = maxTileCoord - endY
                startY += shiftY
                endY += shiftY
            }
            
            // Перебираем все видимые тайлы
            for tileX in (centerTileX - halfTilesX)...(centerTileX + halfTilesX) {
                for tileY in startY...endY {
                    let skip = tileX < 0 || tileY < 0 || tileX > maxTileCoord || tileY > maxTileCoord
                    if skip { continue }
                    
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
        
        let minX = visibleTiles.min(by: { $0.x < $1.x })!.x
        let minY = visibleTiles.min(by: { $0.y < $1.y })!.y
        let maxX = visibleTiles.min(by: { $0.x > $1.x })!.x
        let maxY = visibleTiles.min(by: { $0.y > $1.y })!.y
        
        if Settings.printVisibleAreaRange {
            print("z: \(zoomLevel) x:\(minX)-\(maxX) y:\(minY)-\(maxY)")
        }
        
        return DetVisTilesResult(visibleTiles: visibleTiles,
                                 areaRange: AreaRange(minX: simd_int1(minX),
                                                      minY: simd_int1(minY),
                                                      maxX: simd_int1(maxX),
                                                      maxY: simd_int1(maxY),
                                                      z: simd_int1(zoomLevel)))
    }
}
