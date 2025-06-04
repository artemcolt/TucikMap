//
//  DrawAxis.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit

class DrawAxis {
    // Buffers
    private var positionBuffer: MTLBuffer!
    private var colorBuffer: MTLBuffer!
    private var metalDevice: MTLDevice
    private let mapState: MapZoomState
    private var previousZoom: Int = -1
    
    init(metalDevice: MTLDevice, mapState: MapZoomState) {
        self.metalDevice = metalDevice
        self.mapState = mapState
        createGeometryBuffers()
    }
    
    func createGeometryBuffers() {
        let geometry = GeometryUtils.createAxisGeometry(
            axisLength: Settings.axisLength,
            axisThickness: Settings.axisThickness / mapState.powZoomLevel
        )
        let positions = geometry.0
        let colors = geometry.1
        
        // Create Metal buffers
        positionBuffer = metalDevice.makeBuffer(bytes: positions,
                                               length: positions.count * MemoryLayout<SIMD3<Float>>.stride,
                                               options: .storageModeShared)
        
        colorBuffer = metalDevice.makeBuffer(bytes: colors,
                                            length: colors.count * MemoryLayout<SIMD4<Float>>.stride,
                                            options: .storageModeShared)
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer) {
        if !Settings.drawAxis { return }
        if previousZoom != mapState.zoomLevel {
            createGeometryBuffers()
            previousZoom = mapState.zoomLevel
        }
        
        // Set vertex buffers
        renderEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        
        // Draw the axes as triangles (36 vertices per axis * 3 axes)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36 * 3)
    }
}
