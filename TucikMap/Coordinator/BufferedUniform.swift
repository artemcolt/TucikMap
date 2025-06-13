//
//  BufferedUniform.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

// Uniform data structure to match shader's Uniforms struct
struct Uniforms {
    let projectionMatrix: matrix_float4x4
    let viewMatrix: matrix_float4x4
    let viewportSize: SIMD2<Float>
}



