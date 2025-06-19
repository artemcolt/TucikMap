//
//  TileUniform.swift
//  TucikMap
//
//  Created by Artem on 6/19/25.
//

import MetalKit

struct TileUniform {
    let tileX: simd_int1
    let tileY: simd_int1
    let tileZ: simd_int1
}

struct AllTilesUniform {
    let mapSize: simd_float1
    let panX: simd_float1
    let panY: simd_float1
}

