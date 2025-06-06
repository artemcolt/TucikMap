//
//  ParsedTile.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class ParsedTile {
    let drawingPolygon: DrawingPolygonBytes
    let styles: [TilePolygonStyle]
    var modelMatrix: matrix_float4x4
    let tile: Tile
    
    init(drawingPolygon: DrawingPolygonBytes, styles: [TilePolygonStyle], modelMatrix: matrix_float4x4, tile: Tile) {
        self.drawingPolygon = drawingPolygon
        self.modelMatrix = modelMatrix
        self.styles = styles
        self.tile = tile
    }
}
