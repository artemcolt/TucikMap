//
//  ParsePolygon.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//
import MVTTools
import GISTools
import SwiftEarcut

class ParsePolygon {
    func parse(polygon: [[Coordinate3D]]) -> ParsedPolygon? {
        let extent = Settings.tileExtent
        var vertices: [SIMD2<Float>] = []
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
        
        let triangleIndices = SwiftEarcut.Earcut.tessellate(data: flatCoords, holeIndices: holeIndices)
        // Преобразуем координаты в нормализованные вершины для Metal
        for i in stride(from: 0, to: flatCoords.count, by: 2) {
            let x = Float(flatCoords[i]) / Float(extent) * 2.0 - 1.0
            let y = (1.0 - Float(flatCoords[i + 1]) / Float(extent)) * 2.0 - 1.0
            vertices.append(SIMD2<Float>(x, y))
        }
        
        // Преобразуем индексы в UInt16
        let indices = triangleIndices.map { UInt16($0) }
        if indices.isEmpty { return nil}
        
        return ParsedPolygon(
            vertices: vertices,
            indices: indices
        )
    }
}
