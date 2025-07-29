//
//  DetVisTilesResult.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import MetalKit

struct AreaRange {
    let minX: simd_int1
    let minY: simd_int1
    let maxX: simd_int1
    let maxY: simd_int1
    let z: simd_int1
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
