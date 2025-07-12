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
    let roadLabels: [ParsedRoadLabel]
    
    let drawing3dPolygon: Drawing3dPolygonBytes
    let styles3d: [TilePolygonStyle]
    
    init(
        drawingPolygon: DrawingPolygonBytes,
        styles: [TilePolygonStyle],
        tile: Tile,
        textLabels: [ParsedTextLabel],
        roadLabels: [ParsedRoadLabel],
        drawing3dPolygon: Drawing3dPolygonBytes,
        styles3d: [TilePolygonStyle]
    ) {
        self.drawingPolygon = drawingPolygon
        self.styles = styles
        self.tile = tile
        self.textLabels = textLabels
        self.roadLabels = roadLabels
        
        self.drawing3dPolygon = drawing3dPolygon
        self.styles3d = styles3d
    }
}
