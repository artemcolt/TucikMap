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
    let tile: Tile
    let textLabels: MapLabelsAssembler.Result?
    let textLabelsIds: [UInt]
    
    let vertices3DBuffer: MTLBuffer?
    let indices3DBuffer: MTLBuffer?
    let styles3DBuffer: MTLBuffer
    let indices3DCount: Int
    
    init(
        verticesBuffer: MTLBuffer,
        indicesBuffer: MTLBuffer,
        indicesCount: Int,
        stylesBuffer: MTLBuffer,
        tile: Tile,
        textLabels: MapLabelsAssembler.Result?,
        textLabelsIds: [UInt],
        
        vertices3DBuffer: MTLBuffer?,
        indices3DBuffer: MTLBuffer?,
        styles3DBuffer: MTLBuffer,
        indices3DCount: Int
    ) {
        self.verticesBuffer = verticesBuffer
        self.indicesBuffer = indicesBuffer
        self.indicesCount = indicesCount
        self.stylesBuffer = stylesBuffer
        self.tile = tile
        self.textLabels = textLabels
        self.textLabelsIds = textLabelsIds
        
        self.vertices3DBuffer = vertices3DBuffer
        self.indices3DBuffer = indices3DBuffer
        self.styles3DBuffer = styles3DBuffer
        self.indices3DCount = indices3DCount
    }
}
