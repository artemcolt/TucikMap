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
    private let mapZoomState: MapZoomState
    private let camera: Camera
    private let mapSettings: MapSettings
    
    init(mapZoomState: MapZoomState, camera: Camera, mapSettings: MapSettings) {
        self.mapZoomState = mapZoomState
        self.camera = camera
        self.mapSettings = mapSettings
    }
    
    func determine() -> DetVisTilesResult {
        let realArea = determineRealArea()
        var visibleTiles = realArea.tiles
        let areaRange = realArea.areaRange
        
        let printVisibleTiles = mapSettings.getMapDebugSettings().getPrintVisibleTiles()
        let showOnlyTiles = mapSettings.getMapDebugSettings().getShowOnlyTiles()
        let printVisibleAreaRange = mapSettings.getMapDebugSettings().getPrintVisibleAreaRange()
        if printVisibleTiles {
            print("------")
            for tile in visibleTiles {
                print("x:\(tile.x) y:\(tile.y) z:\(tile.z)")
            }
        }
        
        if showOnlyTiles.count > 0 {
            visibleTiles = fixedTiles()
        }
        
        if printVisibleAreaRange {
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
        var visibleTiles: Set<Tile> = []
        var zoomLevel = mapZoomState.zoomLevel
        
        var centerTileX = camera.centerTileX
        var centerTileY = camera.centerTileY
        let printCenterTile = mapSettings.getMapDebugSettings().getPrintCenterTile()
        let maxTileZoom = mapSettings.getMapCameraSettings().getMaxTileZoom()
        let seeTileInDirection = mapSettings.getMapCommonSettings().getSeeTileInDirection()
        let allowOnlyTiles = mapSettings.getMapDebugSettings().getAllowOnlyTiles()
        if printCenterTile {
            print("centerTileX: \(centerTileX) centerTileY: \(centerTileY) zoomLevel: \(zoomLevel)")
        }
        
        // на больших зумах перестаем уже загружайть тайлы с большим зумом и берем лимитный зум
        if zoomLevel > maxTileZoom {
            let parent = Tile(x: Int(centerTileX), y: Int(centerTileY), z: zoomLevel).findParentTile(atZoom: maxTileZoom)!
            centerTileX = Float(parent.x)
            centerTileY = Float(parent.y)
            zoomLevel = parent.z
        }
        
        let tilesCount = 1 << zoomLevel
        let halfTiles = Float(seeTileInDirection)
        let maxTileCoord = tilesCount - 1
        
        var startY = Int(floor(centerTileY - halfTiles))
        var endY = Int(centerTileY + halfTiles)
        if startY < 0 {
            let shiftY = abs(startY)
            startY += shiftY
            endY += shiftY
        } else if endY > maxTileCoord {
            let shiftY = maxTileCoord - endY
            startY += shiftY
            endY += shiftY
        }
        
        startY = min(max(startY, 0), maxTileCoord)
        endY = min(max(endY, 0), maxTileCoord)
        
        let startX = Int(floor(centerTileX - halfTiles))
        let endX = Int(centerTileX + halfTiles)
        
        var tileXCount: Set<Int> = []
        
        // Перебираем все видимые тайлы
        for tileX in startX...endX {
            for tileY in startY...endY {
                let normTileX = normalize(coord: tileX, z: zoomLevel)
                tileXCount.insert(normTileX)
                
                // Добавляем тайл с текущим уровнем зума
                let tile = Tile(x: normTileX, y: tileY, z: zoomLevel)
                if allowOnlyTiles.isEmpty {
                    visibleTiles.insert(tile)
                } else if allowOnlyTiles.contains(tile) {
                    visibleTiles.insert(tile)
                }
            }
        }
        
        let areaRange = AreaRange(startX: startX,
                                  endX: endX,
                                  minY: startY,
                                  maxY: endY,
                                  z: zoomLevel,
                                  tileXCount: tileXCount.count,
                                  isFullMap: tileXCount.count == tilesCount)
        
        print(areaRange)
        
        return (tiles: Array(visibleTiles), areaRange: areaRange)
    }
    
    private func fixedTiles() -> [Tile] {
        let showOnlyTiles = mapSettings.getMapDebugSettings().getShowOnlyTiles()
        let maxTileZoom = mapSettings.getMapCameraSettings().getMaxTileZoom()
        var visibleTiles: [Tile] = []
        for tile in showOnlyTiles {
            if tile.z > maxTileZoom {
                // Если показ этого тайла невозможен из за ограничений в зуме то нужно найти родительский тайл
                visibleTiles.append(tile.findParentTile(atZoom: maxTileZoom)!)
            } else {
                visibleTiles.append(tile)
            }
        }
        return visibleTiles
    }
}
