//
//  NormalizeLocalCoords.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

class NormalizeLocalCoords {
    static func normalize(flatCoords: [Double], tileExtent: Double) -> [SIMD2<Float>] {
        let extent = tileExtent
        var vertices: [SIMD2<Float>] = []
        for i in stride(from: 0, to: flatCoords.count, by: 2) {
            let x = flatCoords[i] / extent * 2.0 - 1.0
            let y = (1.0 - flatCoords[i + 1] / extent) * 2.0 - 1.0
            vertices.append(SIMD2<Float>(Float(x), Float(y)))
        }
        return vertices
    }
    
    static func normalize(coord: SIMD2<Double>, tileExtent: Double) -> SIMD2<Double> {
        let extent = tileExtent
        let x = coord.x / extent * 2.0 - 1.0
        let y = (1.0 - coord.y / extent) * 2.0 - 1.0
        return SIMD2<Double>(x, y)
    }
}
