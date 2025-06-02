//
//  DetVisTilesResult.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

struct DetVisTilesResult {
    var visibleTiles: [Tile]
    
    func containsTile(tile compare: Tile) -> Bool {
        return visibleTiles.contains { tile in
            tile.x == compare.x && tile.y == compare.y && tile.z == compare.z
        }
    }
}
