//
//  TileResolver.swift
//  TucikMap
//
//  Created by Artem on 6/4/25.
//

import GISTools
import Foundation

class TilesResolver {
    private let getTile: GetTile!
    
    init(getTile: GetTile!) {
        self.getTile = getTile
    }
    
    func findAvailableParent(tile: Tile) -> ParsedTile? {
        var currentZ = tile.z
        var currentX = tile.x
        var currentY = tile.y
        while currentZ > 0 {
            // Вычисляем координаты родителя
            currentZ -= 1 // Уменьшаем уровень зума
            currentX /= 2 // Родительский X (целочисленное деление)
            currentY /= 2 // Родительский Y (целочисленное деление)
            
            // Проверяем, есть ли тайл в кэше
            if let cachedTile = getTile.getCachedTile(tile: Tile(x: currentX, y: currentY, z: currentZ)) {
                return cachedTile
            }
        }
        
        return nil
    }
    
    func resolveTiles(request: ResolveTileRequest) -> ResolvedTiles {
        var actualTiles: [ParsedTile] = []
        var tempTiles: [ParsedTile] = []
        
        for tile in request.tiles {
            // current visible tile is ready
            if let parsedTile = getTile.getCachedTile(tile: tile) {
                actualTiles.append(parsedTile)
                continue
            }
            
            // try to fill using available parent
            if isTileCovered(tile: tile, by: tempTiles) == false {
                if let parent = findAvailableParent(tile: tile) {
                    tempTiles.append(parent)
                }
            }
            
            // don't try to fetch unavailbale tiles
            if request.useOnlyCached { continue }
            
            // download tile
            getTile.fetchTile(request: TileRequest(
                tile: tile,
                view: request.view,
                networkReady: request.networkReady
            ))
        }
        
        return ResolvedTiles(
            actualTiles: actualTiles,
            tempTiles: tempTiles
        )
    }
    
    private func isTileCovered(tile: Tile, by tempTiles: [ParsedTile]) -> Bool {
        for tempTile in tempTiles {
            let tempZ = tempTile.tile.z
            let tempX = tempTile.tile.x
            let tempY = tempTile.tile.y
            let tileZ = tile.z
            let tileX = tile.x
            let tileY = tile.y

            // Проверяем, является ли текущий тайл дочерним для временного тайла
            if tempZ >= tileZ {
                continue // Временный тайл с большим или равным зумом не может покрывать
            }

            // Вычисляем координаты родительского тайла на уровне зума временного тайла
            let parentX = tileX >> (tileZ - tempZ)
            let parentY = tileY >> (tileZ - tempZ)

            // Если координаты совпадают, временный тайл покрывает пробел
            if parentX == tempX && parentY == tempY {
                return true
            }
        }
        return false
    }
}
