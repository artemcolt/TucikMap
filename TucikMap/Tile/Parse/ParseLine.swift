//
//  ParseLine.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//
import MVTTools
import GISTools
import MetalKit

class ParseLine {
    func parseRaw(line: [Coordinate3D], width: Double) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var normal: SIMD2<Double> = SIMD2<Double>(0, 0)

        for i in 0..<line.count {
            let current = SIMD2<Double>(line[i].x, line[i].y)
            
            if i < line.count - 1 {
                let next = SIMD2<Double>(line[i + 1].x, line[i + 1].y)
                let direction = next - current
                normal = normalize(SIMD2<Double>(-direction.y, direction.x))
                
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current + normal * width)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current - normal * width)))
                
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next + normal * width)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next - normal * width)))
                
                let baseIndex = UInt32(i * 4)
                indices.append(baseIndex)     // Верхняя текущая
                indices.append(baseIndex + 2) // Верхняя следующая
                indices.append(baseIndex + 1) // Нижняя текущая
                
                indices.append(baseIndex + 1) // Нижняя текущая
                indices.append(baseIndex + 2) // Верхняя следующая
                indices.append(baseIndex + 3) // Нижняя следующая
                
                // connection of two polygons
                if i < line.count - 2 {
                    let connectionIndex = baseIndex + 2
                    indices.append(connectionIndex)     // Верхняя текущая
                    indices.append(connectionIndex + 2) // Верхняя следующая
                    indices.append(connectionIndex + 1) // Нижняя текущая
                    
                    indices.append(connectionIndex + 1) // Нижняя текущая
                    indices.append(connectionIndex + 2) // Верхняя следующая
                    indices.append(connectionIndex + 3) // Нижняя следующая
                }
            }
        }
        
        return ParsedLineRawVertices(
            vertices: vertices,
            indices: indices
        )
    }
}
