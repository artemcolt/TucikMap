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
    
    let verticesBuffer: MTLBuffer
    let indicesBuffer: MTLBuffer
    let indicesCount: Int
    let stylesBuffer: MTLBuffer
    let textLabels: [ParsedTextLabel]
    let tile: Tile
    
    
    init(
        verticesBuffer: MTLBuffer,
        indicesBuffer: MTLBuffer,
        indicesCount: Int,
        stylesBuffer: MTLBuffer,
        textLabels: [ParsedTextLabel],
        tile: Tile
    ) {
        self.verticesBuffer = verticesBuffer
        self.indicesBuffer = indicesBuffer
        self.indicesCount = indicesCount
        self.stylesBuffer = stylesBuffer
        self.tile = tile
        self.textLabels = textLabels
    }
}
