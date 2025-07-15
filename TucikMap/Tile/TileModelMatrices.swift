//
//  TileModelMatrices.swift
//  TucikMap
//
//  Created by Artem on 7/15/25.
//

import MetalKit

class TileModelMatrices {
    
    private let mapZoomState: MapZoomState
    private let pan: SIMD3<Double>
    private var matrices: [Tile: matrix_float4x4] = [:]
    
    init(mapZoomState: MapZoomState, pan: SIMD3<Double>) {
        self.mapZoomState = mapZoomState
        self.pan = pan
    }
    
    func get(tile: Tile,) -> matrix_float4x4 {
        var current = matrices[tile]
        if current == nil {
            current = tile.getModelMatrix(mapZoomState: mapZoomState, pan: pan)
            matrices[tile] = current
        }
        return current!
    }
}
