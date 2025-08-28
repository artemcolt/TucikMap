//
//  GlobeDrawArea.swift
//  TucikMap
//
//  Created by Artem on 8/27/25.
//

import MetalKit

struct Range {
    let startX: Int
    let endX: Int
    let startY: Int
    let endY: Int
    let z: Int
}

struct GlobeDrawTile {
    let uv: SIMD4<Float>
    
    init(range: Range) {
        let tilesCount = 1 << range.z
        let startTexV = Float(range.startY) / Float(tilesCount)
        let endTexV = (Float(range.endY) + 1) / Float(tilesCount)
        
        let startTexU = Float(range.startX) / Float(tilesCount)
        let endTexU = (Float(range.endX) + 1) / Float(tilesCount)
        let startAndEndUV = SIMD4<Float>(startTexU, endTexU, startTexV, endTexV)
        
        uv = startAndEndUV
    }
}
