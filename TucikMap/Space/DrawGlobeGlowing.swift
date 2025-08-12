//
//  DrawGlobeGlowing.swift
//  TucikMap
//
//  Created by Artem on 8/10/25.
//

import MetalKit


class DrawGlobeGlowing {
    private let metalDevice: MTLDevice
    private let verticesBuffer: MTLBuffer
    
    struct MapParams {
        let factor: Float
        let globeRadius: Float
    };
    
    private struct Vertex {
        var position: SIMD3<Float>
    }
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        
        let vertices: [Vertex] = [
            Vertex(position: SIMD3<Float>(-1, -1, 0)),
            Vertex(position: SIMD3<Float>(1, -1, 0)),
            Vertex(position: SIMD3<Float>(-1, 1, 0)),
            Vertex(position: SIMD3<Float>(1, 1, 0)),
        ]
        verticesBuffer = metalDevice.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)!
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, mapParams: MapParams, uniformsBuffer: MTLBuffer) {
        var mapParams = mapParams
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&mapParams, length: MemoryLayout<MapParams>.stride, index: 2)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
