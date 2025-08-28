//
//  DrawSpace.swift
//  TucikMap
//
//  Created by Artem on 8/10/25.
//

import MetalKit

class DrawSpace {
    private struct Vertex {
        var position: SIMD4<Float>
        var pointSize: Float
        var color: SIMD4<Float>
    }
    
    private let starCount = 1000
    private let starDistance: Float = 1.0
    private let metalDevice: MTLDevice
    private let vertexBuffer: MTLBuffer
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        
        var vertices = [Vertex]()
        while vertices.count < starCount {
            // Генерация равномерного направления на сфере
            let u = Float.random(in: -1..<1)
            let theta = Float.random(in: 0..<2 * Float.pi)
            let sqrt_term = sqrt(1 - u * u)
            
            let x = sqrt_term * cos(theta) * starDistance
            let y = sqrt_term * sin(theta) * starDistance
            let z = u * starDistance
            
            let size = Float.random(in: 10...21) // Размер точки
            let brightness = Float.random(in: 0.6...2.0)
            let color = SIMD4<Float>(brightness, brightness, brightness, 1.0) // Белые звёзды
            
            vertices.append(Vertex(position: SIMD4<Float>(x, y, z, 1), pointSize: size, color: color))
        }
        
        vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: starCount)
    }
}
