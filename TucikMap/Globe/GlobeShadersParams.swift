//
//  GlobeShadersParams.swift
//  TucikMap
//
//  Created by Artem on 8/28/25.
//

struct GlobeShadersParams {
    let latitude            : Float
    let longitude           : Float
    let scale               : Float
    let uShift              : Float
    let globeRadius         : Float
    let transition          : Float
    let startAndEndUV       : SIMD4<Float>
    let planeNormal         : SIMD3<Float>
}
