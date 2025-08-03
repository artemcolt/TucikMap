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
        let frustrumPassed: Bool
    }
    
    struct LoopedTile: Hashable {
        let tile: Tile
        let loop: Int
        
        static func == (lhs_: LoopedTile, rhs_: LoopedTile) -> Bool {
            let lhs = lhs_.tile
            let rhs = rhs_.tile
            return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs_.loop == rhs_.loop
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(tile)
            hasher.combine(loop)
        }
    }
    
    private let frustrum: FrustrumCulling
    private let mapZoomState: MapZoomState
    private let pan: SIMD3<Double>
    private let areaRange: AreaRange
    private var properties: [LoopedTile: Props] = [:]
    
    
    init(mapZoomState: MapZoomState, pan: SIMD3<Double>, uniforms: Uniforms, areaRange: AreaRange) {
        self.mapZoomState   = mapZoomState
        self.pan            = pan
        self.areaRange      = areaRange
        
        frustrum            = FrustrumCulling(projection: uniforms.projectionMatrix, view: uniforms.viewMatrix)
    }
    
    func get(tile: Tile, loop: Int) -> Props {
        let loopedTile = LoopedTile(tile: tile, loop: loop)
        var current = properties[loopedTile]
        if current == nil {
            let modelMatrix     = tile.getModelMatrix(mapZoomState: mapZoomState, pan: pan)
            let mapScaleFactor  = pow(2.0, Float(areaRange.z))
            let loopMatrix      = MatrixUtils.matrix_translate(Settings.mapSize * mapScaleFactor * Float(loop), 0, 0)
            let loopedModel     = loopMatrix * modelMatrix
            
            let bounds = frustrum.createBounds(modelMatrix: loopedModel)
            let frustrumPassed = frustrum.contains(bounds: bounds)
            
            current = Props(model: loopedModel, frustrumPassed: frustrumPassed)
            properties[loopedTile] = current
        }
        
        return current!
    }
}
