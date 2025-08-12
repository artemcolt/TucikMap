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
    
    init(basePipeline: BasePipeline,
         metalDevice: MTLDevice,
         cameraStorage: CameraStorage,
         textPipeline: TextPipeline,
         drawUI: DrawUI,
         drawPoint: DrawPoint,
         mapZoomState: MapZoomState) {
        self.basePipeline = basePipeline
        self.cameraStorage = cameraStorage
        self.textPipeline = textPipeline
        self.drawUI = drawUI
        self.mapZoomState = mapZoomState
        self.drawPoint = drawPoint
        
        drawAxes = DrawAxes(metalDevice: metalDevice)
    }
    
    func draw(renderPassWrapper: RenderPassWrapper, uniformsBuffer: MTLBuffer, view: MTKView) {
        let renderEncoder = renderPassWrapper.createUIEncoder()
        basePipeline.selectPipeline(renderEncoder: renderEncoder)
        drawPoint.draw(
            renderEncoder: renderEncoder,
            uniformsBuffer: uniformsBuffer,
            pointSize: Settings.cameraCenterPointSize,
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
}
