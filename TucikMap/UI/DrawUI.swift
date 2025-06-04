//
//  DrawUI.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class DrawUI {
    private let cameraUI: CameraUI
    private let textTools: TextTools
    private let mapZoomState: MapZoomState
    private var size: CGSize = CGSize()
    
    init(device: MTLDevice, textTools: TextTools, mapZoomState: MapZoomState) {
        cameraUI = CameraUI(device: device)
        self.textTools = textTools
        self.mapZoomState = mapZoomState
    }
    
    func updateSize(size: CGSize) {
        self.size = size
        cameraUI.updateMatrix(size: size)
    }
    
    func drawZoomUiText(
        renderCommandEncoder: MTLRenderCommandEncoder
    ) {
        let zoomLevelFloat = mapZoomState.zoomLevelFloat
        let drawTextData = textTools.textAssembler.assembleBytes(
            lines: [TextAssembler.TextLineData(
                text: "z:\(zoomLevelFloat)",
                offset: SIMD3<Float>(30, Float(size.height) - Float(250.0), 0),
                rotation: SIMD3<Float>(0, 0, 0),
                scale: 80)
            ],
            font: textTools.font
        )
        
        textTools.drawText.renderTextBytes(
            renderEncoder: renderCommandEncoder,
            uniforms: cameraUI.uniformsBuffer,
            drawTextData: drawTextData
        )
    }
}
