//
//  MetalTile.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import MetalKit

class MetalTile {
    let verticesBuffer: MTLBuffer
    let indicesBuffer: MTLBuffer
    let indicesCount: Int
    let stylesBuffer: MTLBuffer
    let modelMatrixBuffer: MTLBuffer
    let tile: Tile
    
    init(verticesBuffer: MTLBuffer, indicesBuffer: MTLBuffer, indicesCount: Int, stylesBuffer: MTLBuffer, modelMatrixBuffer: MTLBuffer, tile: Tile) {
        self.verticesBuffer = verticesBuffer
        self.indicesBuffer = indicesBuffer
        self.indicesCount = indicesCount
        self.stylesBuffer = stylesBuffer
        self.modelMatrixBuffer = modelMatrixBuffer
        self.tile = tile
    }
}
