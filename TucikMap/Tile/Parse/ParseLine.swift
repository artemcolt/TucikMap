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
    func parseRaw2(line: [Coordinate3D], width: Double) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var baseVertexIndex: UInt32 = 0
        for coord in line {
            let delta = 0.5
            vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: SIMD2<Double>(coord.x - delta, coord.y - delta))))
            vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: SIMD2<Double>(coord.x + delta, coord.y - delta))))
            vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: SIMD2<Double>(coord.x + delta, coord.y + delta))))
            vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: SIMD2<Double>(coord.x - delta, coord.y + delta))))
            
            let baseIndex = baseVertexIndex
            indices.append(baseIndex + 3)
            indices.append(baseIndex + 1)
            indices.append(baseIndex + 2)
            
            indices.append(baseIndex)
            indices.append(baseIndex + 3)
            indices.append(baseIndex + 1)
            
            baseVertexIndex += 4
        }
        
        return ParsedLineRawVertices(
            vertices: vertices,
            indices: indices
        )
    }
    
    func parseRaw1(line: [Coordinate3D], width: Double) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var normal: SIMD2<Double> = SIMD2<Double>(0, 0)
        
        if line.count > 1 {
            var baseVertexIndex: UInt32 = 0
            
            // Process line segments
            for i in 0..<line.count - 1 {
                let current = SIMD2<Double>(line[i].x, line[i].y)
                let next = SIMD2<Double>(line[i + 1].x, line[i + 1].y)
                let direction = current - next
                normal = normalize(SIMD2<Double>(-direction.y, direction.x))
                let shift = normal * width
                
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current + shift)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current - shift)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next + shift)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next - shift)))
                
                indices.append(baseVertexIndex)
                indices.append(baseVertexIndex + 1)
                indices.append(baseVertexIndex + 2)
                
                indices.append(baseVertexIndex + 3)
                indices.append(baseVertexIndex + 2)
                indices.append(baseVertexIndex + 1)
                
                
                // Connection of two segments
//                if i < line.count - 2 {
//                    let connectionIndex = baseIndex + 2
//                    indices.append(connectionIndex)     // Top current
//                    indices.append(connectionIndex + 2) // Top next
//                    indices.append(connectionIndex + 1) // Bottom current
//                    
//                    indices.append(connectionIndex + 1) // Bottom current
//                    indices.append(connectionIndex + 2) // Top next
//                    indices.append(connectionIndex + 3) // Bottom next
//                }
                
                baseVertexIndex += 4
            }
        }
        
        return ParsedLineRawVertices(
            vertices: vertices,
            indices: indices
        )
    }
    
    func parseRaw(line: [Coordinate3D], width: Double) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var normal: SIMD2<Double> = SIMD2<Double>(0, 0)
        
        // Number of segments for semicircular caps
        let capSegments = 16
        
        // Helper function to add semicircular cap
        func addSemicircularCap(center: SIMD2<Double>, direction: SIMD2<Double>, isStart: Bool, baseVertexIndex: inout UInt32) {
            let normal = normalize(SIMD2<Double>(-direction.y, direction.x))
            let centerVertex = SIMD2<Float>(NormalizeLocalCoords.normalize(coord: center))
            vertices.append(centerVertex)
            let centerIndex = baseVertexIndex
            baseVertexIndex += 1
            
            // Generate vertices for the semicircle
            let startAngle = isStart ? .pi : 0.0
            let endAngle = isStart ? 0.0 : .pi
            let angleStep = (endAngle - startAngle) / Double(capSegments)
            
            for i in 0...capSegments {
                let angle = startAngle + Double(i) * angleStep
                let offset = SIMD2<Double>(cos(angle), sin(angle)) * width
                let rotatedOffset = offset.x * normal + offset.y * (isStart ? -direction : direction)
                let capVertex = SIMD2<Float>(NormalizeLocalCoords.normalize(coord: center + rotatedOffset))
                vertices.append(capVertex)
                
                if i < capSegments {
                    indices.append(centerIndex)
                    indices.append(baseVertexIndex + UInt32(i))
                    indices.append(baseVertexIndex + UInt32(i + 1))
                }
            }
            baseVertexIndex += UInt32(capSegments + 1)
        }
        
        // Add start cap
        if line.count > 1 {
            var baseVertexIndex: UInt32 = 0
            let start = SIMD2<Double>(line[0].x, line[0].y)
            let next = SIMD2<Double>(line[1].x, line[1].y)
            var direction = normalize(next - start)
            addSemicircularCap(center: start, direction: direction, isStart: true, baseVertexIndex: &baseVertexIndex)
            
            // Process line segments
            for i in 0..<line.count - 1 {
                let current = SIMD2<Double>(line[i].x, line[i].y)
                let next = SIMD2<Double>(line[i + 1].x, line[i + 1].y)
                let direction = next - current
                normal = normalize(SIMD2<Double>(-direction.y, direction.x))
                
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current + normal * width)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current - normal * width)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next + normal * width)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next - normal * width)))
                
                let baseIndex = baseVertexIndex
                indices.append(baseIndex)     // Top current
                indices.append(baseIndex + 2) // Top next
                indices.append(baseIndex + 1) // Bottom current
                
                indices.append(baseIndex + 1) // Bottom current
                indices.append(baseIndex + 2) // Top next
                indices.append(baseIndex + 3) // Bottom next
                
                // Connection of two segments
                if i < line.count - 2 {
                    let connectionIndex = baseIndex + 2
                    indices.append(connectionIndex)     // Top current
                    indices.append(connectionIndex + 2) // Top next
                    indices.append(connectionIndex + 1) // Bottom current
                    
                    indices.append(connectionIndex + 1) // Bottom current
                    indices.append(connectionIndex + 2) // Top next
                    indices.append(connectionIndex + 3) // Bottom next
                }
                
                baseVertexIndex += 4
            }
            
            // Add end cap
            let end = SIMD2<Double>(line[line.count - 1].x, line[line.count - 1].y)
            let prev = SIMD2<Double>(line[line.count - 2].x, line[line.count - 2].y)
            direction = normalize(end - prev)
            addSemicircularCap(center: end, direction: direction, isStart: false, baseVertexIndex: &baseVertexIndex)
        }
        
        return ParsedLineRawVertices(
            vertices: vertices,
            indices: indices
        )
    }
}
