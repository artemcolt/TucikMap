//
//  MetalTile.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import MetalKit


class MetalTile: Hashable {
    static func == (lhs: MetalTile, rhs: MetalTile) -> Bool {
        return lhs.tile.x == rhs.tile.x && lhs.tile.z == rhs.tile.z && lhs.tile.y == rhs.tile.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tile.x)
        hasher.combine(tile.y)
        hasher.combine(tile.z)
    }
    
    let tile2dBuffers: Tile2dBuffers
    let tile3dBuffers: Tile3dBuffers
    
    let tile: Tile
    let roadLabels: MapRoadLabelsAssembler.Result?
    
    let parsedTile: ParsedTile
    
    init(
        tile: Tile,
        tile2dBuffers: Tile2dBuffers,
        tile3dBuffers: Tile3dBuffers,
        roadLabels: MapRoadLabelsAssembler.Result?,
        parsedTile: ParsedTile
    ) {
        self.tile = tile
        self.tile2dBuffers = tile2dBuffers
        self.tile3dBuffers = tile3dBuffers
        self.roadLabels = roadLabels
        
        self.parsedTile = parsedTile
    }
}
