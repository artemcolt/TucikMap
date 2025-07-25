//
//  GlobeGeometry.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import Foundation
import simd

class GlobeGeometry {
    func createPlane(segments: Int) -> [GlobePipeline.Vertex] {
        var vertices: [GlobePipeline.Vertex] = []
        
        let size = Float(0.5)
        let startFrom = -size / 2
        
        // Ensure segments is at least 1 to avoid invalid grid
        let segments = max(1, segments)
        
        // Calculate step size for positions and texture coordinates
        let step = 1.0 / Float(segments)
        
        // Generate vertices for the grid
        for i in 0...segments { // строки
            for j in 0...segments { // колонки
                // Position: Map i, j to a plane centered at (0, 0) with size 2x2 (from -1 to 1)
                let x = startFrom + size * Float(j) * step
                let y = startFrom + size * Float(i) * step
                
                // Texture coordinates: Map i, j to [0, 1] range
                let u = Float(j) * step
                let v = Float(i) * step
                
                // Create vertex (assuming GlobePipeline.Vertex has position and texCoord)
                let vertex = GlobePipeline.Vertex(
                    position: SIMD2<Float>(x, y),
                    planeCoord: SIMD2<Float>(u, v)
                )
                vertices.append(vertex)
            }
        }
        
        // Generate indices for triangles
        var triangleVertices: [GlobePipeline.Vertex] = []
        let width = segments + 1 // Number of vertices per row
        
        for i in 0..<segments {
            for j in 0..<segments {
                // Indices for the two triangles forming a quad
                let v0 = i * width + j
                let v1 = v0 + 1
                let v2 = (i + 1) * width + j
                let v3 = v2 + 1
                
                // First triangle: v0, v2, v1
                triangleVertices.append(vertices[v0])
                triangleVertices.append(vertices[v2])
                triangleVertices.append(vertices[v1])
                
                // Second triangle: v1, v2, v3
                triangleVertices.append(vertices[v1])
                triangleVertices.append(vertices[v2])
                triangleVertices.append(vertices[v3])
            }
        }
        
        return triangleVertices
    }
}
