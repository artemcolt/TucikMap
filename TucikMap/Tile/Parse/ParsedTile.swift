//
//  ParsedTile.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

struct ParsedTile {
    let drawingPolygonBuffers: DrawingPolygonBuffers
    let tile: Tile
    let stylesBuffer: MTLBuffer
    let modelMatrixBuffer: MTLBuffer
}
