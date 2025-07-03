//
//  ParseBuilding.swift
//  TucikMap
//
//  Created by Artem on 7/2/25.
//

import MetalKit
import MVTTools
import GISTools
import SwiftEarcut
import Foundation

class ParseBuilding {
    func parseBuilding(polygon: [[Coordinate3D]], parsePolygon: ParsePolygon, height: Double) -> Parsed3dPolygon? {
            let height = Float(height)
            guard let polygon = parsePolygon.parse(polygon: polygon) else { return nil }
            
            // Roof vertices and indices
            let roofVertices: [SIMD3<Float>] = polygon.vertices.map { vertex in SIMD3<Float>(vertex.x, vertex.y, Float(height)) }
            let roofIndices: [UInt32] = polygon.indices
            
            // Wall vertices and indices
            var wallVertices: [SIMD3<Float>] = []
            var wallIndices: [UInt32] = []
            
            // For each vertex in the polygon, create ground and roof vertices for walls
            for i in 0..<polygon.vertices.count {
                let current = polygon.vertices[i]
                let next = polygon.vertices[(i + 1) % polygon.vertices.count]
                
                // Wall vertices: bottom-left, bottom-right, top-right, top-left
                let v0 = SIMD3<Float>(Float(current.x), Float(current.y), 0.0) // Bottom-left
                let v1 = SIMD3<Float>(Float(next.x), Float(next.y), 0.0)     // Bottom-right
                let v2 = SIMD3<Float>(Float(next.x), Float(next.y), height)   // Top-right
                let v3 = SIMD3<Float>(Float(current.x), Float(current.y), height) // Top-left
                
                // Add vertices to the wall vertices array
                let baseIndex = UInt32(wallVertices.count)
                wallVertices.append(contentsOf: [v0, v1, v2, v3])
                
                // Add indices for two triangles per wall face (quad: v0-v1-v2-v3)
                // Triangle 1: v0-v1-v2
                wallIndices.append(contentsOf: [baseIndex, baseIndex + 1, baseIndex + 2])
                // Triangle 2: v0-v2-v3
                wallIndices.append(contentsOf: [baseIndex, baseIndex + 2, baseIndex + 3])
            }
            
            // Combine roof and wall geometry
            let combinedVertices = roofVertices + wallVertices
            let combinedIndices = roofIndices + wallIndices.map { $0 + UInt32(roofVertices.count) }
            
            return Parsed3dPolygon(vertices: combinedVertices, indices: combinedIndices)
        }
}
