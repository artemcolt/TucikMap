//
//  DrawDebugData.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import MetalKit

class DrawDebugData {
    private let textPipeline    : TextPipeline
    private let drawPoint       : DrawPoint
    private let drawAxes        : DrawAxes
    private let drawUI          : DrawUI
    private let cameraStorage   : CameraStorage
    private let mapZoomState    : MapZoomState
    private let mapSettings     : MapSettings
    
    private let depthStencilState: MTLDepthStencilState
    
    init(metalDevice: MTLDevice,
         cameraStorage: CameraStorage,
         textPipeline: TextPipeline,
         drawUI: DrawUI,
         drawPoint: DrawPoint,
         mapZoomState: MapZoomState,
         mapSettings: MapSettings) {
        self.cameraStorage = cameraStorage
        self.textPipeline = textPipeline
        self.drawUI = drawUI
        self.mapZoomState = mapZoomState
        self.drawPoint = drawPoint
        self.mapSettings = mapSettings
        
        drawAxes = DrawAxes(metalDevice: metalDevice)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, view: MTKView) {
        let cameraCenterPointSize = mapSettings.getMapDebugSettings().getCameraCenterPointSize()
        drawPoint.draw(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: cameraCenterPointSize * cameraStorage.currentView.distortion,
            position: cameraStorage.currentView.targetPosition,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        drawAxes.draw(renderEncoder: renderEncoder,
                      uniformsBuffer: uniformsBuffer,
                      lineLength: 1.0,
                      position: SIMD3<Float>(0, 0, 0)
        )
        
        textPipeline.selectPipeline(renderEncoder: renderEncoder)
        drawUI.drawZoomUiText(renderCommandEncoder: renderEncoder, size: view.drawableSize, mapZoomState: mapZoomState)
    }
    
    
    func drawGlobeTraversalPlane(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, planeNormal: SIMD3<Float>) {
        renderEncoder.setDepthStencilState(depthStencilState)
        
        let planeOrigin = SIMD3<Float>(0, 0, -cameraStorage.currentView.globeRadius)
        let size: Float = 0.6 * mapZoomState.powZoomLevel  // Example parameter; adjust as needed

        let unitNormal = normalize(planeNormal)
        let half = size / 2

        // Choose an arbitrary vector not parallel to the normal
        var arbitrary = SIMD3<Float>(0, 0, 1)
        if abs(dot(unitNormal, arbitrary)) > 0.999 {
            arbitrary = SIMD3<Float>(1, 0, 0)
        }

        // Compute orthonormal basis for the plane
        let tangent = normalize(cross(arbitrary, unitNormal))
        let bitangent = cross(unitNormal, tangent)

        // Compute the four corner vertices of the square centered at planeOrigin
        let v1 = planeOrigin - half * tangent - half * bitangent
        let v2 = planeOrigin + half * tangent - half * bitangent
        let v3 = planeOrigin + half * tangent + half * bitangent
        let v4 = planeOrigin - half * tangent + half * bitangent

        // 6 vertices for two triangles (with duplication, no indices), ordered to ensure correct winding matching the normal direction
        var vertices: [SIMD3<Float>] = [v1, v3, v2, v1, v4, v3]
        
        var colors = vertices.map { vert in SIMD4<Float>(0, 1, 0, 0.85) }
        renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<SIMD3<Float>>.stride * vertices.count, index: 0)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.endEncoding()
    }
    
    
    func drawGlobePoint(renderEncoder: MTLRenderCommandEncoder) {
        let color = SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        let cameraCenterPointSize = mapSettings.getMapDebugSettings().getCameraCenterPointSize()
        let position = cameraStorage.currentView.targetPosition
        let pointSize = cameraCenterPointSize * cameraStorage.currentView.distortion
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        
        // Create a simple square (two triangles) for the point, centered at the given position
        let halfSize = pointSize / 2
        // Triangle 1
        positions.append(SIMD3<Float>(position.x - halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y + halfSize, position.z))
        // Triangle 2
        positions.append(SIMD3<Float>(position.x - halfSize, position.y - halfSize, position.z))
        positions.append(SIMD3<Float>(position.x + halfSize, position.y + halfSize, position.z))
        positions.append(SIMD3<Float>(position.x - halfSize, position.y + halfSize, position.z))
        
        // Add red color for each vertex
        for _ in 0..<6 {
            colors.append(color)
        }
        
        // Set vertex buffers
        renderEncoder.setVertexBytes(&positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        renderEncoder.setVertexBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        
        // Draw the point as two triangles (6 vertices)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        let position = SIMD3<Float>(0, 0, 0)
        let lineLength: Float = 1.0
        
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        
        // X axis (red)
        positions.append(position)
        positions.append(position + SIMD3<Float>(lineLength, 0, 0))
        colors.append(SIMD4<Float>(1, 0, 0, 1))
        colors.append(SIMD4<Float>(1, 0, 0, 1))
        
        // Y axis (green)
        positions.append(position)
        positions.append(position + SIMD3<Float>(0, lineLength, 0))
        colors.append(SIMD4<Float>(0, 1, 0, 1))
        colors.append(SIMD4<Float>(0, 1, 0, 1))
        
        // Z axis (blue)
        positions.append(position)
        positions.append(position + SIMD3<Float>(0, 0, lineLength))
        colors.append(SIMD4<Float>(0, 0, 1, 1))
        colors.append(SIMD4<Float>(0, 0, 1, 1))
        
        // Set vertex buffers
        renderEncoder.setVertexBytes(&positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        renderEncoder.setVertexBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        
        // Draw the axes as three separate lines (6 vertices)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 6)
    }
}
