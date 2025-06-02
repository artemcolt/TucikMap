//
//  TileRequest.swift
//  TucikMap
//
//  Created by Artem on 5/31/25.
//

import MetalKit

struct TileRequest {
    var tile: Tile
    var view: MTKView
    
    var networkReady: (NewTile) -> Void
}
