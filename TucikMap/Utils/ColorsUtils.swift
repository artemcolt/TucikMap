//
//  ColorsUtils.swift
//  TucikMap
//
//  Created by Artem on 8/15/25.
//

import simd

class ColorsUtils {
    static func blend(source: SIMD4<Float>, destination: SIMD4<Float>) -> SIMD4<Float> {
        let sourceAlpha = source.w
        let oneMinusSourceAlpha = 1 - sourceAlpha
        
        let sourceXYZ = SIMD3<Float>(source.x, source.y, source.z)
        let destinationXYZ = SIMD3<Float>(destination.x, destination.y, destination.z)
        
        // Blended RGB: (source.rgb * sourceAlpha) + (destination.rgb * oneMinusSourceAlpha)
        let blendedRGB = (sourceXYZ * sourceAlpha) + (destinationXYZ * oneMinusSourceAlpha)

        // Blended Alpha: (sourceAlpha * sourceAlpha) + (destination.w * oneMinusSourceAlpha)
        let blendedAlpha = (sourceAlpha * sourceAlpha) + (destination.w * oneMinusSourceAlpha)

        let resultingColor = SIMD4<Float>(blendedRGB.x, blendedRGB.y, blendedRGB.z, blendedAlpha)
        return resultingColor
    }
}
