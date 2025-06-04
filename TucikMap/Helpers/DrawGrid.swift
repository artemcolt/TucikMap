//
//  DrawGrid.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import SwiftUI
import MetalKit

class DrawGrid {
    // Buffers
    private var positionBuffer: MTLBuffer!
    private var colorBuffer: MTLBuffer!
    private var metalDevice: MTLDevice
    private var lastZ: Int = -1
    private var lastX: Int = -1
    private var lastY: Int = -1
    private let cellCount = 1
    private var vertexCount: Int = 0
    private var mapZoomState: MapZoomState
    
    init(metalDevice: MTLDevice, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.mapZoomState = mapZoomState
    }
    
    func createGeometryBuffers(gridThickness: Float = 0.01, camTileX: Int, camTileY: Int) {
        // Recreate geometry only if cell size has changed
        if mapZoomState.zoomLevel == lastZ && camTileX == lastX && camTileY == lastY { return }
        
        lastZ = mapZoomState.zoomLevel
        lastX = camTileX
        lastY = camTileY
        
        let cellSize = mapZoomState.tileSize
        let gridExtent: Float = mapZoomState.tileSize * Float(cellCount)
        let shiftY = Settings.mapSize / 2.0 - Float(camTileY) * cellSize
        let shiftX = Float(camTileX) * cellSize - Settings.mapSize / 2.0
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        let twiceGridExtent = 2 * gridExtent
        
        // Generate grid lines along X-axis
        for i in -2 * cellCount...cellCount {
            let pos = Float(i) * cellSize + shiftY
            // Horizontal line (along X)
            positions.append(SIMD3<Float>(-gridExtent + shiftX, pos - gridThickness / 2, 0))
            positions.append(SIMD3<Float>(twiceGridExtent + shiftX, pos - gridThickness / 2, 0))
            positions.append(SIMD3<Float>(twiceGridExtent + shiftX, pos + gridThickness / 2, 0))
            positions.append(SIMD3<Float>(-gridExtent + shiftX, pos - gridThickness / 2, 0))
            positions.append(SIMD3<Float>(twiceGridExtent + shiftX, pos + gridThickness / 2, 0))
            positions.append(SIMD3<Float>(-gridExtent + shiftX, pos + gridThickness / 2, 0))
            
            // Add color for each vertex (gray color)
            for _ in 0..<6 {
                colors.append(SIMD4<Float>(0.5, 0.5, 0.5, 1.0))
            }
        }
        
        // Generate grid lines along Y-axis
        for i in -cellCount...2 * cellCount {
            let pos = Float(i) * cellSize + shiftX
            // Vertical line (along Y)
            positions.append(SIMD3<Float>(pos - gridThickness / 2, -twiceGridExtent + shiftY, 0))
            positions.append(SIMD3<Float>(pos + gridThickness / 2, -twiceGridExtent + shiftY, 0))
            positions.append(SIMD3<Float>(pos + gridThickness / 2, gridExtent + shiftY, 0))
            positions.append(SIMD3<Float>(pos - gridThickness / 2, -twiceGridExtent + shiftY, 0))
            positions.append(SIMD3<Float>(pos + gridThickness / 2, gridExtent + shiftY, 0))
            positions.append(SIMD3<Float>(pos - gridThickness / 2, gridExtent + shiftY, 0))
            
            // Add color for each vertex (gray color)
            for _ in 0..<6 {
                colors.append(SIMD4<Float>(0.5, 0.5, 0.5, 1.0))
            }
        }
        
        // Create Metal buffers
        positionBuffer = metalDevice.makeBuffer(bytes: positions,
                                               length: positions.count * MemoryLayout<SIMD3<Float>>.stride,
                                               options: .storageModeShared)
        
        colorBuffer = metalDevice.makeBuffer(bytes: colors,
                                            length: colors.count * MemoryLayout<SIMD4<Float>>.stride,
                                            options: .storageModeShared)
        
        vertexCount = positions.count
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, camTileX: Int, camTileY: Int, gridThickness: Float = 0.01) {
        if Settings.drawGrid == false {return}
        // Recreate geometry if needed
        createGeometryBuffers(
            gridThickness: gridThickness,
            camTileX: camTileX,
            camTileY: camTileY
        )
        
        // Set vertex buffers
        renderEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        
        // Draw the grid as triangles
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
