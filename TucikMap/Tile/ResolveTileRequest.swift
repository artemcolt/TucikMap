//
//  ResolveTileRequest.swift
//  TucikMap
//
//  Created by Artem on 6/4/25.
//

import SwiftUI
import MetalKit

struct ResolveTileRequest {
    let view: MTKView
    let networkReady: (NewTile) -> Void
    let tiles: [Tile]
    let useOnlyCached: Bool
}
