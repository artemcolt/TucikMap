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
    
    init(device: MTLDevice, textTools: TextTools, screenUniforms: ScreenUniforms) {
        self.screenUniforms = screenUniforms
        self.textTools = textTools
    }
    
    func drawZoomUiText(
        renderCommandEncoder: MTLRenderCommandEncoder,
        size: CGSize,
        mapZoomState: MapZoomState
    ) {
        let zoomLevelFloat = mapZoomState.zoomLevelFloat
        let formattedString = String(format: "z:%.3f", zoomLevelFloat)
        let drawTextData = textTools.textAssembler.assembleBytes(
            lines: [TextAssembler.TextLineData(
                text: formattedString,
                offset: SIMD3<Float>(30, Float(size.height) - Float(250.0), 0),
                rotation: SIMD3<Float>(0, 0, 0),
                scale: 80)
            ],
            font: textTools.baseFont
        )
        
        textTools.drawText.renderTextBytes(
            renderEncoder: renderCommandEncoder,
            drawTextData: drawTextData
        )
    }
}
