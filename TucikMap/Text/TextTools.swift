//
//  TextUtils.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class TextTools {
    let createTextGeometry = CreateTextGeometry()
    let textAssembler: TextAssembler
    let font: Font
    let drawText: DrawText
    private let fontLoader: FontLoader
    private let metalDevice: MTLDevice
    
    init(metalDevice: MTLDevice) {
        self.metalDevice =  metalDevice
        fontLoader = FontLoader(metalDevice: metalDevice)
        font = fontLoader.load(fontName: "Roboto-Regular")
        drawText = DrawText(metalDevice: metalDevice)
        textAssembler = TextAssembler(createTextGeometry: createTextGeometry, metalDevice: metalDevice)
    }
}
