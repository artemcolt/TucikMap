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
    fileprivate let mapZoomState            : MapZoomState
    fileprivate let camera                  : Camera
    fileprivate let mapSettings             : MapSettings
    fileprivate var seeTileInDirection      : Int { get { return 0 } }
    
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
            for visTile in visibleTiles {
                let tile = visTile.tile
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
        return MapMathUtils.normalizeCoord(coord: coord, z: z)
    }
    
    private func determineRealArea() -> (tiles: [VisibleTile], areaRange: AreaRange)  {
        var visibleTiles: Set<Tile> = []
        var zoomLevel = mapZoomState.zoomLevel
        
        var centerTileX = camera.centerTileX
        var centerTileY = camera.centerTileY
        let printCenterTile = mapSettings.getMapDebugSettings().getPrintCenterTile()
        let maxTileZoom = mapSettings.getMapCameraSettings().getMaxTileZoom()
        
        let allowOnlyTiles = mapSettings.getMapDebugSettings().getAllowOnlyTiles()
        if printCenterTile {
            print("centerTileX: \(centerTileX) centerTileY: \(centerTileY) zoomLevel: \(zoomLevel)")
        }
        
        // На больших зумах перестаем уже загружайть тайлы с большим зумом и берем лимитный зум
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
        
        // cортируем в порядке самых нужных
        // сначала будут расположены тайлы которые ближе всего к камере
        let visibleTilesList = getVisTilesFromTiles(visibleTiles: Array(visibleTiles))
        
        return (tiles: visibleTilesList, areaRange: areaRange)
    }
    
    private func getVisTilesFromTiles(visibleTiles: [Tile]) -> [VisibleTile] {
        let centerTileX = Int(camera.centerTileX)
        let centerTileY = Int(camera.centerTileY)
        
        // cортируем в порядке самых нужных
        // сначала будут расположены тайлы которые ближе всего к камере
        var visibleTilesList = Array(visibleTiles).map { tile in
            let dx1 = abs(tile.x - centerTileX)
            let dy1 = abs(tile.y - centerTileY)
            return VisibleTile(tile: tile, tilesFromCenterTile: SIMD2<Int>(dx1, dy1))
        }
        visibleTilesList.sort { tile1, tile2 in
            let distSq1 = tile1.tilesFromCenterTile.x + tile1.tilesFromCenterTile.y
            let distSq2 = tile2.tilesFromCenterTile.x + tile2.tilesFromCenterTile.y
            return distSq1 > distSq2
        }
        return visibleTilesList
    }
    
    private func fixedTiles() -> [VisibleTile] {
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
        
        // cортируем в порядке самых нужных
        // сначала будут расположены тайлы которые ближе всего к камере
        let visibleTilesList = getVisTilesFromTiles(visibleTiles: visibleTiles)
        return visibleTilesList
    }
}


class DetermineVisibleTilesGlobe: DetermineVisibleTiles {
    override fileprivate var seeTileInDirection: Int { get { return mapSettings.getMapCommonSettings().getSeeTileInDirectionGlobe() } }
}


class DetermineVisibleTilesFlat: DetermineVisibleTiles {
    override fileprivate var seeTileInDirection: Int { get { return mapSettings.getMapCommonSettings().getSeeTileInDirectionFlat() } }
}
