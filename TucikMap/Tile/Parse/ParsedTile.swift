//
//  ParsedTile.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

struct ParsedTile {
    let drawingPolygonBuffers: [UInt8 : DrawingPolygonBuffers]
    let tile: Tile
    let styles: [UInt8 : FeatureStyle]
    let modelMatrixBuffer: MTLBuffer
}
