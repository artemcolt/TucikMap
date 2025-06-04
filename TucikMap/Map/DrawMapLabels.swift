//
//  DrawMapLabels.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

import MetalKit

class DrawMapLabels {
    private let textTools: TextTools
    private var drawTextData: DrawTextData
    
    init(textTools: TextTools) {
        self.textTools = textTools
        
        drawTextData = textTools.textAssembler.assemble(
            lines: [
                TextAssembler.TextLineData(
                    text: "Moscow",
                    offset: SIMD3<Float>(0, 0, 5),
                    rotation: SIMD3<Float>(0, 0, 0),
                    scale: 100
                )
            ],
            font: textTools.font
        )
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, uniforms: MTLBuffer) {
        textTools.drawText.renderText(
            renderEncoder: renderEncoder,
            uniforms: uniforms,
            drawTextData: drawTextData
        )
    }
}
