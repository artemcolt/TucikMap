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
    static let localTileBounds = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: Double(Settings.tileExtent), longitude: Double(Settings.tileExtent))
    )
    
    init(getTile: GetTile!) {
        self.getTile = getTile
    }
    
    func findAvailableParent(tile: Tile) -> Tile? {
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
                return cachedTile.tile
            }
        }
        
        return nil
    }
    
    func resolveTiles(request: ResolveTileRequest) -> [ParsedTile] {
        var tileToAssemble: [ParsedTile] = []
        for tile in request.tiles {
            // current visible tile is ready
            if let parsedTile = getTile.getCachedTile(tile: tile) {
                tileToAssemble.append(parsedTile)
                continue
            }
            
            // try to fill using available parent
//            if let parent = findAvailableParent(tile: tile) {
//                let parentX = parent.x
//                let parentY = parent.y
//                let parentZ = parent.z
//                
//                let tileX = tile.x
//                let tileY = tile.y
//                let tileZ = tile.z
//                
//                let deltaZ = tileZ - parentZ
//                let scale = pow(2.0, Double(deltaZ)) // 2^deltaZ
//                
//                // Размер тайла в системе координат родителя
//                let tileSizeInParent = 4096.0 / scale
//                
//                // Рассчитываем координаты дочернего тайла в системе родителя
//                let relativeX = Double(tileX - parentX * Int(scale)) * tileSizeInParent
//                let relativeY = Double(tileY - parentY * Int(scale)) * tileSizeInParent
//                
//                // Определяем boundingBox для обрезки родительского тайла
//                let boundingBox = BoundingBox(
//                    southWest: Coordinate3D(x: relativeX, y: relativeY),
//                    northEast: Coordinate3D(x: relativeX + tileSizeInParent, y: relativeY + tileSizeInParent)
//                )
//                let parsedTile = getTile.getTileClipped(tile: parent, boundingBox: boundingBox)!
//                tileToAssemble.append(parsedTile)
//            }
            
            // download tile
            getTile.fetchTile(request: TileRequest(
                tile: tile,
                view: request.view,
                boundingBox: TilesResolver.localTileBounds,
                networkReady: request.networkReady
            ))
        }
        
        return tileToAssemble
    }
}
