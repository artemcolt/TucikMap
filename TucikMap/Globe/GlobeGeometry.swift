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
    
    func createPlane(segments: Int) -> PlaneData {
        let yStep = Float(2.0) / Float(segments)
        let xStep = Float(2.0) / Float(segments)
        
        var vertices: [GlobePipeline.Vertex] = []
        for xSegment in 0...segments {
            let xCoord = -1.0 + xStep * Float(xSegment)
            
            for ySegment in 0...segments {
                let yCoord = -1.0 + Float(ySegment) * yStep
                
                let u = Float(ySegment) / Float(segments)
                let v = Float(xSegment) / Float(segments)
                
                vertices.append(GlobePipeline.Vertex(texcoord: SIMD2<Float>(u, 1 - v),
                                                     xCoord: xCoord,
                                                     yCoord: yCoord))
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
                //indices.append(contentsOf: [bl, tl, br, br, tl, tr])
                indices.append(contentsOf: [tr, tl, br, br, tl, bl])
            }
        }
        
        return PlaneData(vertices: vertices, indices: indices)
    }
}
