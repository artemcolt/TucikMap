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
        
        let realArea = determineRealArea()
        var visibleTiles = realArea.tiles
        let areaRange = realArea.areaRange
        
        if Settings.printVisibleTiles {
            print(visibleTiles)
        }
        
        if Settings.showOnlyTiles.count > 0 {
            visibleTiles = fixedTiles()
        }
        
        if Settings.printVisibleAreaRange {
            print("z: \(areaRange.z) startX:\(areaRange.startX) endX:\(areaRange.endX) minY:\(areaRange.minY) maxY:\(areaRange.maxY)")
        }
        
        return DetVisTilesResult(visibleTiles: visibleTiles,
                                 areaRange: areaRange)
    }
    
    private func normalize(coord: Int, z: Int) -> Int {
        let n = 1 << z
        var normalized = coord % n
        if normalized < 0 {
            normalized += n
        }
        return normalized
    }
    
    private func determineRealArea() -> (tiles: [Tile], areaRange: AreaRange)  {
        var visibleTiles: [Tile] = []
        var zoomLevel = mapZoomState.zoomLevel
        
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
        
        var startX = centerTileX - halfTilesX
        var endX = centerTileX + halfTilesX
        
        // Кастомно настраиваем видимую область для малых зумов
        switch zoomLevel {
        case 0:
            startX = 0
            endX = 0
            startY = 0
            endY = 0
        case 1:
            startX = 0
            endX = 1
            startY = 0
            endY = 1
        default: break
        }
        
        let areaRange = AreaRange(startX: startX, endX: endX, minY: startY, maxY: endY, z: zoomLevel)
        
        // Перебираем все видимые тайлы
        for tileX in startX...endX {
            for tileY in startY...endY {
                if tileY < 0 || tileY > maxTileCoord { continue }
                
                let normTileX = normalize(coord: tileX, z: zoomLevel)
                
                // Добавляем тайл с текущим уровнем зума
                let tile = Tile(x: normTileX, y: tileY, z: zoomLevel)
                if Settings.allowOnlyTiles.isEmpty {
                    visibleTiles.append(tile)
                } else if Settings.allowOnlyTiles.contains(tile) {
                    visibleTiles.append(tile)
                }
            }
        }
        
        return (tiles: visibleTiles, areaRange: areaRange)
    }
    
    private func fixedTiles() -> [Tile] {
        var visibleTiles: [Tile] = []
        for tile in Settings.showOnlyTiles {
            if tile.z > Settings.maxTileZoom {
                // Если показ этого тайла невозможен из за ограничений в зуме то нужно найти родительский тайл
                visibleTiles.append(tile.findParentTile(atZoom: Settings.maxTileZoom)!)
            } else {
                visibleTiles.append(tile)
            }
        }
        return visibleTiles
    }
}
