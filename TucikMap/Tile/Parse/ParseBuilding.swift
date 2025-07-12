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
import simd

class ParseBuilding {
    func parseBuilding(polygon: [[Coordinate3D]], parsePolygon: ParsePolygon, height: Double) -> Parsed3dPolygon? {
        let height = Float(height)
        guard let parsed = parsePolygon.parse(polygon: polygon) else { return nil }
        
        // Roof vertices and indices
        let roofVertices: [SIMD3<Float>] = parsed.vertices.map { vertex in SIMD3<Float>(vertex.x, vertex.y, height) }
        let roofIndices: [UInt32] = parsed.indices
        let roofNormals: [SIMD3<Float>] = Array(repeating: SIMD3<Float>(0, 0, 1), count: roofVertices.count)
        
        var combinedVertices: [SIMD3<Float>] = roofVertices
        var combinedIndices: [UInt32] = roofIndices
        var combinedNormals: [SIMD3<Float>] = roofNormals
        
        // Find boundary edges
        var edgeToCount: [UInt64: Int] = [:]
        for i in stride(from: 0, to: roofIndices.count, by: 3) {
            let a = roofIndices[i]
            let b = roofIndices[i + 1]
            let c = roofIndices[i + 2]
            
            let abKey = (UInt64(a) << 32) | UInt64(b)
            let bcKey = (UInt64(b) << 32) | UInt64(c)
            let caKey = (UInt64(c) << 32) | UInt64(a)
            
            edgeToCount[abKey, default: 0] += 1
            edgeToCount[bcKey, default: 0] += 1
            edgeToCount[caKey, default: 0] += 1
        }
        
        var boundaryEdges: [(UInt32, UInt32)] = []
        for (key, count) in edgeToCount {
            if count == 1 {
                let u = UInt32(key >> 32)
                let v = UInt32(key & 0xFFFFFFFF)
                let revKey = (UInt64(v) << 32) | UInt64(u)
                let revCount = edgeToCount[revKey, default: 0]
                if revCount == 0 {
                    boundaryEdges.append((u, v))
                }
            }
        }
        
        // Build walls
        for (u, v) in boundaryEdges {
            let bottomU2D = parsed.vertices[Int(u)]
            let bottomV2D = parsed.vertices[Int(v)]
            let bottomU = SIMD3<Float>(bottomU2D.x, bottomU2D.y, 0)
            let bottomV = SIMD3<Float>(bottomV2D.x, bottomV2D.y, 0)
            let topU = roofVertices[Int(u)]
            let topV = roofVertices[Int(v)]
            
            let vec = bottomV2D - bottomU2D
            let dx = vec.x
            let dy = vec.y
            let len = sqrt(dx * dx + dy * dy)
            if len <= 0 {
                continue
            }
            let normal = SIMD3<Float>(dy / len, -dx / len, 0)
            
            let base = UInt32(combinedVertices.count)
            combinedVertices.append(contentsOf: [bottomU, bottomV, topV, topU])
            combinedNormals.append(contentsOf: [normal, normal, normal, normal])
            combinedIndices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
        }
        
        return Parsed3dPolygon(
            vertices: combinedVertices,
            normals: combinedNormals,
            indices: combinedIndices
        )
    }
}
