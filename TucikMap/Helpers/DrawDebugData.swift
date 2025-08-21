//
//  DrawDebugData.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import MetalKit

class DrawDebugData {
    private let basePipeline    : BasePipeline
    private let textPipeline    : TextPipeline
    private let drawPoint       : DrawPoint
    private let drawAxes        : DrawAxes
    private let drawUI          : DrawUI
    private let cameraStorage   : CameraStorage
    private let mapZoomState    : MapZoomState
    private let mapSettings     : MapSettings
    
    private let depthStencilState: MTLDepthStencilState
    
    init(basePipeline: BasePipeline,
         metalDevice: MTLDevice,
         cameraStorage: CameraStorage,
         textPipeline: TextPipeline,
         drawUI: DrawUI,
         drawPoint: DrawPoint,
         mapZoomState: MapZoomState,
         mapSettings: MapSettings) {
        self.basePipeline = basePipeline
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
    
    func draw(renderPassWrapper: RenderPassWrapper, uniformsBuffer: MTLBuffer, view: MTKView) {
        let renderEncoder = renderPassWrapper.createUIEncoder()
        let cameraCenterPointSize = mapSettings.getMapDebugSettings().getCameraCenterPointSize()
        basePipeline.selectPipeline(renderEncoder: renderEncoder)
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
        renderEncoder.endEncoding()
    }
    
    
    func drawGlobeTraversalPlane(renderPassWrapper: RenderPassWrapper, uniformsBuffer: MTLBuffer, planeNormal: SIMD3<Float>) {
        let renderEncoder = renderPassWrapper.createGlobeTransversalEncoder()
        basePipeline.selectPipelineWithDepthStencil(renderEncoder: renderEncoder)
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
        renderEncoder.setVertexBytes(&colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.endEncoding()
    }
}
