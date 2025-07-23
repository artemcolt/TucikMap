//
//  ModelMatrices.swift
//  TucikMap
//
//  Created by Artem on 7/22/25.
//

import MetalKit

class ModelMatrices {
    private var matrices: [matrix_float4x4] = []
    private var tileToIndex: [Tile:Int] = [:]
    private var mapZoomState: MapZoomState
    private var mapPanning: SIMD3<Double>
    
    func getMatricesArray() -> [matrix_float4x4] {
        return matrices
    }
    
    init(mapZoomState: MapZoomState, mapPanning: SIMD3<Double>) {
        self.mapZoomState = mapZoomState
        self.mapPanning = mapPanning
    }
    
    func getMatrix(tile: Tile) -> Int {
        var indexTo = tileToIndex[tile]
        if indexTo == nil {
            let modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile, mapZoomState: mapZoomState, pan: mapPanning)
            indexTo = matrices.count
            tileToIndex[tile] = indexTo
            matrices.append(modelMatrix)
        }
        return indexTo!
    }
}
