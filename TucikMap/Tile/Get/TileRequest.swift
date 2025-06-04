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
    let isBoundsLocal: Bool
    var networkReady: (NewTile) -> Void
    
    init(tile: Tile, view: MTKView, boundingBox: BoundingBox, networkReady: @escaping (NewTile) -> Void) {
        self.tile = tile
        self.view = view
        self.boundingBox = boundingBox
        self.networkReady = networkReady
        let extent = Double(Settings.tileExtent)
        self.isBoundsLocal = boundingBox.southWest.x == 0 && boundingBox.southWest.y == 0 &&
                             boundingBox.northEast.x == extent && boundingBox.northEast.y == extent
    }
}
