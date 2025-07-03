//
//  ParsePolygon.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit
import MVTTools
import GISTools
import SwiftEarcut

class ParsePolygon {
    func parse(polygon: [[Coordinate3D]]) -> ParsedPolygon? {
        var flatCoords: [Double] = []
        var holeIndices: [Int] = []
        for (ringIndex, ring) in polygon.enumerated() {
            if ringIndex > 0 {
                holeIndices.append(flatCoords.count / 2)
            }
            for coord in ring.dropLast() {
                flatCoords.append(coord.x)
                flatCoords.append(coord.y)
            }
        }
        
        let triangleIndices = SwiftEarcut.Earcut.tessellate(data: flatCoords, holeIndices: holeIndices, dim: 2)
        let vertices: [SIMD2<Float>] = NormalizeLocalCoords.normalize(flatCoords: flatCoords)
        
        // Преобразуем индексы в UInt16
        let indices: [UInt32] = triangleIndices.map { UInt32($0) }
        if indices.isEmpty { return nil}
        
        return ParsedPolygon(
            vertices: vertices,
            indices: indices
        )
    }
}
