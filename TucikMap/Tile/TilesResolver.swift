//
//  TileResolver.swift
//  TucikMap
//
//  Created by Artem on 6/4/25.
//

import GISTools
import Foundation
import MetalKit

class TilesResolver {
    private let metalTiles: MetalTilesStorage!
    
    init(determineStyle: DetermineFeatureStyle, metalDevice: MTLDevice, onProcessedTiles: @escaping () -> Void) {
        metalTiles = MetalTilesStorage(determineStyle: determineStyle, metalDevice: metalDevice, onProcessedTiles: onProcessedTiles)
    }
    
    func findAvailableParent(tile: Tile) -> MetalTile? {
        var currentZ = tile.z
        var currentX = tile.x
        var currentY = tile.y
        while currentZ > 0 {
            // Вычисляем координаты родителя
            currentZ -= 1 // Уменьшаем уровень зума
            currentX /= 2 // Родительский X (целочисленное деление)
            currentY /= 2 // Родительский Y (целочисленное деление)
            
            // Проверяем, есть ли тайл в кэше
            if let metalTile = metalTiles.getMetalTile(tile: Tile(x: currentX, y: currentY, z: currentZ)) {
                return metalTile
            }
        }
        
        return nil
    }
    
    func resolveTiles(request: ResolveTileRequest) -> ResolvedTiles {
        var actualTiles: [MetalTile] = []
        var tempTiles: [MetalTile] = []
        metalTiles.setupTilesFilter(filterTiles: request.visibleTiles)
        
        for tile in request.visibleTiles {
            // current visible tile is ready
            if let metalTile = metalTiles.getMetalTile(tile: tile) {
                actualTiles.append(metalTile)
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
            
            metalTiles.requestMetalTile(tile: tile)
        }
        
        return ResolvedTiles(
            actualTiles: actualTiles,
            tempTiles: tempTiles
        )
    }
    
    private func isTileCovered(tile: Tile, by tempTiles: [MetalTile]) -> Bool {
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
