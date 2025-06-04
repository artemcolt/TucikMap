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
    func parse(line: [Coordinate3D]) -> ParsedLine {
        var linePoints: [LinePoint] = []
        
        for i in 0..<line.count {
            let current = SIMD2<Float>(Float(line[i].x), Float(line[i].y))
            
            var normal: SIMD2<Float>
            if i < line.count - 1 {
                let next = SIMD2<Float>(Float(line[i + 1].x), Float(line[i + 1].y))
                let direction = next - current
                normal = normalize(SIMD2<Float>(-direction.y, direction.x))
            } else {
                normal = linePoints.last!.normal
            }
            
            let normalizedPoint = NormalizeLocalCoords.normalize(coord: current)
            linePoints.append(LinePoint(point: normalizedPoint, normal: normal))
        }
        
        return ParsedLine(points: linePoints)
    }
    
    func parseRaw(line: [Coordinate3D], width: Float) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var normal: SIMD2<Float> = SIMD2<Float>(0, 0)

        for i in 0..<line.count {
            let current = SIMD2<Float>(Float(line[i].x), Float(line[i].y))
            
            if i < line.count - 1 {
                let next = SIMD2<Float>(Float(line[i + 1].x), Float(line[i + 1].y))
                let direction = next - current
                normal = normalize(SIMD2<Float>(-direction.y, direction.x))
                
                vertices.append(NormalizeLocalCoords.normalize(coord: current + normal * width))
                vertices.append(NormalizeLocalCoords.normalize(coord: current - normal * width))
                
                vertices.append(NormalizeLocalCoords.normalize(coord: next + normal * width))
                vertices.append(NormalizeLocalCoords.normalize(coord: next - normal * width))
                
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
