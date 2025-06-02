//
//  DrawTextData.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

struct DrawTextData {
    let vertexBuffer: MTLBuffer
    let glyphPropBuffer: MTLBuffer
    let verticesCount: Int
    let atlas: MTLTexture
}

struct DrawTextDataBytes {
    let vertices: [TextVertex]
    let glyphProps: [GlyphGpuProp]
    let verticesCount: Int
    let atlas: MTLTexture
}
