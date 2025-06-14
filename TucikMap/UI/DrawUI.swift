//
//  DrawUI.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class DrawUI {
    private let screenUniforms: ScreenUniforms
    private let textTools: TextTools
    private let mapZoomState: MapZoomState
    
    init(device: MTLDevice, textTools: TextTools, mapZoomState: MapZoomState, screenUniforms: ScreenUniforms) {
        self.screenUniforms = screenUniforms
        self.textTools = textTools
        self.mapZoomState = mapZoomState
    }
    
    func drawZoomUiText(
        renderCommandEncoder: MTLRenderCommandEncoder,
        size: CGSize
    ) {
        let zoomLevelFloat = mapZoomState.zoomLevelFloat
        let drawTextData = textTools.textAssembler.assembleBytes(
            lines: [TextAssembler.TextLineData(
                text: "z:\(zoomLevelFloat)",
                offset: SIMD3<Float>(30, Float(size.height) - Float(250.0), 0),
                rotation: SIMD3<Float>(0, 0, 0),
                scale: 80)
            ],
            font: textTools.robotoFont.regularFont
        )
        
        textTools.drawText.renderTextBytes(
            renderEncoder: renderCommandEncoder,
            uniforms: screenUniforms.screenUniformBuffer,
            drawTextData: drawTextData
        )
    }
}
