//
//  TileRequest.swift
//  TucikMap
//
//  Created by Artem on 5/31/25.
//

import MetalKit
import GISTools

struct TileRequest {
    let tile: Tile
    let view: MTKView
    let boundingBox: BoundingBox
    var tileReady: (NewTile) -> Void
    
    init(tile: Tile, view: MTKView, networkReady: @escaping (NewTile) -> Void) {
        self.tile = tile
        self.view = view
        self.tileReady = networkReady
        let extent = Double(Settings.tileExtent)
        boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: extent, longitude: extent)
        )
    }
}
