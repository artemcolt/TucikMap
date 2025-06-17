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
    let tile: Tile
    let textLabels: [ParsedTextLabel]
    
    init(
        drawingPolygon: DrawingPolygonBytes,
        styles: [TilePolygonStyle],
        tile: Tile,
        textLabels: [ParsedTextLabel]
    ) {
        self.drawingPolygon = drawingPolygon
        self.styles = styles
        self.tile = tile
        self.textLabels = textLabels
    }
}
