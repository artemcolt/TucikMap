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
    func parseRaw(line: [Coordinate3D], width: Double, tileExtent: Double) -> ParsedLineRawVertices {
        var vertices: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        var normal: SIMD2<Double> = SIMD2<Double>(0, 0)
        
        // Number of segments for semicircular caps
        let capSegments = 16
        
        // Helper function to add semicircular cap
        func addSemicircularCap(center: SIMD2<Double>, direction: SIMD2<Double>, isStart: Bool, tileExtent: Double, baseVertexIndex: inout UInt32) {
            let normal = normalize(SIMD2<Double>(-direction.y, direction.x))
            let centerVertex = SIMD2<Float>(NormalizeLocalCoords.normalize(coord: center, tileExtent: tileExtent))
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
                let capVertex = SIMD2<Float>(NormalizeLocalCoords.normalize(coord: center + rotatedOffset, tileExtent: tileExtent))
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
            addSemicircularCap(center: start, direction: direction, isStart: true, tileExtent: tileExtent, baseVertexIndex: &baseVertexIndex)
            
            // Process line segments
            for i in 0..<line.count - 1 {
                let current = SIMD2<Double>(line[i].x, line[i].y)
                let next = SIMD2<Double>(line[i + 1].x, line[i + 1].y)
                let direction = next - current
                normal = normalize(SIMD2<Double>(-direction.y, direction.x))
                
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current + normal * width, tileExtent: tileExtent)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: current - normal * width, tileExtent: tileExtent)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next + normal * width, tileExtent: tileExtent)))
                vertices.append(SIMD2<Float>(NormalizeLocalCoords.normalize(coord: next - normal * width, tileExtent: tileExtent)))
                
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
            addSemicircularCap(center: end, direction: direction, isStart: false, tileExtent: tileExtent, baseVertexIndex: &baseVertexIndex)
        }
        
        return ParsedLineRawVertices(
            vertices: vertices,
            indices: indices
        )
    }
}
