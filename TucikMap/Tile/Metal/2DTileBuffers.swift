//
//  2DTileBuffers.swift
//  TucikMap
//
//  Created by Artem on 7/3/25.
//

import MetalKit

struct Tile2dBuffers {
    let verticesBuffer: MTLBuffer
    let indicesBuffer: MTLBuffer
    let stylesBuffer: MTLBuffer
    let indicesCount: Int
}
