//
//  FrustrumCulling.swift
//  TucikMap
//
//  Created by Artem on 7/17/25.
//

import MetalKit
import simd


class FrustrumCulling {
    struct TileBounds {
        let lb: SIMD2<Float> // left  bottom world point z = 0
        let rb: SIMD2<Float> // right bottom world point z = 0
        let rt: SIMD2<Float> // right top    world point z = 0
        let lt: SIMD2<Float> // left  top    world point z = 0
    }
    
    struct Frustum {
        private var planes: [simd_float4] = []
        
        init(projectionView: float4x4) {
            let row0 = simd_float4(projectionView.columns.0[0], projectionView.columns.1[0], projectionView.columns.2[0], projectionView.columns.3[0])
            let row1 = simd_float4(projectionView.columns.0[1], projectionView.columns.1[1], projectionView.columns.2[1], projectionView.columns.3[1])
            let row2 = simd_float4(projectionView.columns.0[2], projectionView.columns.1[2], projectionView.columns.2[2], projectionView.columns.3[2])
            let row3 = simd_float4(projectionView.columns.0[3], projectionView.columns.1[3], projectionView.columns.2[3], projectionView.columns.3[3])
            
            let left = row3 + row0
            let right = row3 - row0
            let bottom = row3 + row1
            let top = row3 - row1
            let near = row2
            let far = row3 - row2
            
            planes = [
                normalize(plane: left),
                normalize(plane: right),
                normalize(plane: bottom),
                normalize(plane: top),
                normalize(plane: near),
                normalize(plane: far)
            ]
        }
        
        private func normalize(plane: simd_float4) -> simd_float4 {
            let len = simd_length(simd_float3(plane.x, plane.y, plane.z))
            return len > 1e-8 ? plane / len : plane
        }
        
        func containsTile(bounds: TileBounds) -> Bool {
            let points: [simd_float4] = [
                simd_float4(bounds.lb.x, bounds.lb.y, 0, 1),
                simd_float4(bounds.rb.x, bounds.rb.y, 0, 1),
                simd_float4(bounds.rt.x, bounds.rt.y, 0, 1),
                simd_float4(bounds.lt.x, bounds.lt.y, 0, 1)
            ]
            
            for plane in planes {
                var allOutside = true
                for point in points {
                    if simd_dot(plane, point) >= 0 {
                        allOutside = false
                        break
                    }
                }
                if allOutside {
                    return false
                }
            }
            return true
        }
    }
    
    private let frustrum: Frustum
    
    init(projection: matrix_float4x4, view: matrix_float4x4) {
        let pv = projection * view
        frustrum = Frustum(projectionView: pv)
    }
    
    func contains(bounds: FrustrumCulling.TileBounds) -> Bool {
        return frustrum.containsTile(bounds: bounds)
    }
}
