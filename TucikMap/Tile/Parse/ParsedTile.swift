//
//  ParsedTile.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

struct ParsedTile {
    var drawingPolygonData: [UInt8 : DrawingPolygonData] = [:]
    var zoom: Int
    var x: Int
    var y: Int
}
