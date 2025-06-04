//
//  ParsedTile.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

struct ParsedTile {
    let drawingPolygonBytes: [UInt8 : DrawingPolygonBytes]
    let tile: Tile
    let styles: [UInt8 : FeatureStyle]
}
