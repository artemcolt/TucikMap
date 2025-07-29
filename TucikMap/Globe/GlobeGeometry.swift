//
//  GlobeGeometry.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import Foundation
import simd

class GlobeGeometry {
    struct PlaneData {
        let vertices: [GlobePipeline.Vertex]
        let indices: [UInt32]
    }
    
    func createPlane(segments: Int, areaRange: AreaRange) -> PlaneData {
        let maxY = Float(areaRange.maxY)
        let minY = Float(areaRange.minY)
        let z = Int(areaRange.z)
        
        let tilesNum = pow(2.0, Float(z))
        let initialY = -(minY / tilesNum) * 2 + 1
        let finalY = -((maxY + 1) / tilesNum) * 2 + 1
        
        let ySize = abs(finalY - initialY)
        let yStep = ySize / Float(segments)
        
        let minX = Float(areaRange.minX)
        let maxX = Float(areaRange.maxX)
        
        let initialX = (minX / tilesNum) * 2 - 1
        let finalX = ((maxX + 1) / tilesNum) * 2 - 1
        let xSize = abs(finalX - initialX)
        let xStep = xSize / Float(segments)
        let xHalfSize = xSize / 2
        
        var vertices: [GlobePipeline.Vertex] = []
        for j in 0...segments {
            let yCoord = finalY + yStep * Float(j)
            for i in 0...segments {
                let u = Float(i) / Float(segments)
                let v = Float(j) / Float(segments)
                
                let xCoord = -xHalfSize + Float(i) * xStep
                
                vertices.append(GlobePipeline.Vertex(texcoord: SIMD2<Float>(1 - u, 1 - v),
                                                     yCoord: yCoord,
                                                     xCoord: xCoord))
            }
        }
        
        var indices: [UInt32] = []
        let width = segments + 1
        for j in 0..<segments {
            for i in 0..<segments {
                let bl = UInt32(j * width + i)
                let br = bl + 1
                let tl = UInt32((j + 1) * width + i)
                let tr = tl + 1
                indices.append(contentsOf: [bl, tl, br, br, tl, tr])
            }
        }
        
        return PlaneData(vertices: vertices, indices: indices)
    }
}
