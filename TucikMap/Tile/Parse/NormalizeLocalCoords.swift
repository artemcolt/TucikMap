//
//  NormalizeLocalCoords.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

class NormalizeLocalCoords {
    static func normalize(flatCoords: [Double], ) -> [SIMD2<Float>] {
        let extent = Settings.tileExtent
        var vertices: [SIMD2<Float>] = []
        for i in stride(from: 0, to: flatCoords.count, by: 2) {
            let x = Float(flatCoords[i]) / Float(extent) * 2.0 - 1.0
            let y = (1.0 - Float(flatCoords[i + 1]) / Float(extent)) * 2.0 - 1.0
            vertices.append(SIMD2<Float>(x, y))
        }
        return vertices
    }
    
    static func normalize(coord: SIMD2<Float>) -> SIMD2<Float> {
        let extent = Settings.tileExtent
        let x = coord.x / Float(extent) * 2.0 - 1.0
        let y = (1.0 - coord.y / Float(extent)) * 2.0 - 1.0
        return SIMD2<Float>(x, y)
    }
}
