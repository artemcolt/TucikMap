//
//  DetVisTilesResult.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit

struct AreaRange {
    let startX: Int
    let endX: Int
    let minY: Int
    let maxY: Int
    let z: Int
    let tileXCount: Int
    let isFullMap: Bool
    
    static func == (lhs: AreaRange, rhs: AreaRange) -> Bool {
        return lhs.startX == rhs.startX &&
               lhs.minY == rhs.minY &&
               lhs.endX == rhs.endX &&
               lhs.maxY == rhs.maxY &&
               lhs.z == rhs.z
    }
}

struct DetVisTilesResult {
    var visibleTiles: [Tile]
    let areaRange: AreaRange
    
    func containsTile(tile compare: Tile) -> Bool {
        return visibleTiles.contains { tile in
            tile.x == compare.x && tile.y == compare.y && tile.z == compare.z
        }
    }
}
