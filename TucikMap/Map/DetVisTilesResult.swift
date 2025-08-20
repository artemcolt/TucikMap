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

struct VisibleTile {
    let tile: Tile
    let tilesFromCenterTile: SIMD2<Float>
}

struct DetVisTilesResult {
    var visibleTiles: [VisibleTile]
    let areaRange: AreaRange
    
    func containsTile(tile compare: Tile) -> Bool {
        return visibleTiles.contains { visTile in
            visTile.tile.x == compare.x && visTile.tile.y == compare.y && visTile.tile.z == compare.z
        }
    }
}
