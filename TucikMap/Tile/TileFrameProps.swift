//
//  TileModelMatrices.swift
//  TucikMap
//
//  Created by Artem on 7/15/25.
//

import MetalKit

class TileFrameProps {
    struct Props {
        let model: matrix_float4x4
        let contains: Bool
    }
    
    private let frustrum: FrustrumCulling
    private let mapZoomState: MapZoomState
    private let pan: SIMD3<Double>
    private var properties: [Tile: Props] = [:]
    
    init(mapZoomState: MapZoomState, pan: SIMD3<Double>, uniforms: Uniforms) {
        self.mapZoomState   = mapZoomState
        self.pan            = pan
        
        frustrum            = FrustrumCulling(projection: uniforms.projectionMatrix, view: uniforms.viewMatrix)
    }
    
    func get(tile: Tile) -> Props {
        var current = properties[tile]
        if current == nil {
            let modelMatrix = tile.getModelMatrix(mapZoomState: mapZoomState, pan: pan)
            
            let lb              = modelMatrix * simd_float4(-1, -1, 0, 1)
            let rb              = modelMatrix * simd_float4( 1, -1, 0, 1)
            let rt              = modelMatrix * simd_float4( 1,  1, 0, 1)
            let lt              = modelMatrix * simd_float4(-1,  1, 0, 1)
            
            let lb2             = SIMD2<Float>(lb.x, lb.y)
            let rb2             = SIMD2<Float>(rb.x, rb.y)
            let rt2             = SIMD2<Float>(rt.x, rt.y)
            let lt2             = SIMD2<Float>(lt.x, lt.y)
            
            let bounds          = FrustrumCulling.TileBounds(lb: lb2, rb: rb2, rt: rt2, lt: lt2)
            let contains        = frustrum.contains(bounds: bounds)
            current             = Props(model: modelMatrix, contains: contains)
            
            properties[tile] = current
        }
        return current!
    }
}
