//
//  DrawGlobeGeom.swift
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

import MetalKit

class DrawGlobeGeom {
    private let metalDevice: MTLDevice
    private let verticesBuffer: MTLBuffer
    private let verticesCount: Int
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        
        let radius: Float = Settings.nullZoomGlobeRadius
        let latitudeBands: Int = 30
        let longitudeBands: Int = 30
        
        var vertices: [GlobeGeomPipeline.VertexIn] = []
        
        // Generate unique vertices in a grid (latitudeBands + 1 rows, longitudeBands + 1 columns)
        for lat in 0...latitudeBands {
            let theta = Float(lat) * Float.pi / Float(latitudeBands)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            
            for lon in 0...longitudeBands {
                let phi = Float(lon) * 2 * Float.pi / Float(longitudeBands)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)
                
                let x = cosPhi * sinTheta * radius
                let y = cosTheta * radius
                let z = sinPhi * sinTheta * radius
                
                vertices.append(GlobeGeomPipeline.VertexIn(position: SIMD3<Float>(x, y, z)))
            }
        }
        
        // Now generate the triangle vertices (with duplicates) for drawing with .triangle
        var triangleVertices: [GlobeGeomPipeline.VertexIn] = []
        
        let slices = longitudeBands + 1  // Number of vertices per latitude row
        
        for lat in 0..<latitudeBands {
            for lon in 0..<longitudeBands {
                // Define the four corners of the quad
                let topLeft = vertices[lat * slices + lon]
                let topRight = vertices[lat * slices + lon + 1]
                let bottomLeft = vertices[(lat + 1) * slices + lon]
                let bottomRight = vertices[(lat + 1) * slices + lon + 1]
                
                // First triangle: topLeft, bottomLeft, topRight
                triangleVertices.append(topLeft)
                triangleVertices.append(bottomLeft)
                triangleVertices.append(topRight)
                
                // Second triangle: topRight, bottomLeft, bottomRight
                triangleVertices.append(topRight)
                triangleVertices.append(bottomLeft)
                triangleVertices.append(bottomRight)
            }
        }
        
        verticesCount = triangleVertices.count
        verticesBuffer = metalDevice.makeBuffer(bytes: triangleVertices,
                                                length: MemoryLayout<GlobeGeomPipeline.VertexIn>.stride * triangleVertices.count)!
    }
    
    func drawGeom(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, mapParams: GlobeGeomPipeline.MapParams) {
        var mapParams = mapParams
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&mapParams, length: MemoryLayout<GlobeGeomPipeline.MapParams>.stride, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
    }
}
