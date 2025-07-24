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
        
        // Ensure segments is at least 1
        let segments = max(1, segments)
        
        // Calculate step size for a square from -1 to 1
        let step = 2.0 / Float(segments)
        
        // Generate vertices for a grid of triangles
        for i in 0..<segments {
            for j in 0..<segments {
                // Calculate base coordinates for the quad
                let x0 = -1.0 + Float(j) * step
                let x1 = x0 + step
                let y0 = -1.0 + Float(i) * step
                let y1 = y0 + step
                
                let tx0 = (x0 + 1.0) / 2.0
                let tx1 = (x1 + 1.0) / 2.0
                let ty0 = (1.0 - y0) / 2.0
                let ty1 = (1.0 - y1) / 2.0
                
                // First triangle (bottom-left)
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx0, ty0)))
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx1, ty0)))
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx0, ty1)))
                
                // Second triangle (top-right)
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx1, ty0)))
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx1, ty1)))
                vertices.append(GlobePipeline.Vertex(texCoord: SIMD2<Float>(tx0, ty1)))
            }
        }
        
        return vertices
    }
}
