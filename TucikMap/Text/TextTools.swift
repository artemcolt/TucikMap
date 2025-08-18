//
//  TextUtils.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class TextTools {
    let createTextGeometry: CreateTextGeometry
    let textAssembler: TextAssembler
    let mapLabelsAssembler: MapLabelsAssembler
    let mapRoadLabelsAssembler: MapRoadLabelsAssembler
    let drawText: DrawText
    private let fontLoader: FontLoader
    private let metalDevice: MTLDevice
    
    private let regularFont: Font
    private let boldFont: Font
    let robotoFont: FontBatch
    
    init(metalDevice: MTLDevice, frameCounter: FrameCounter, mapSettings: MapSettings) {
        self.metalDevice = metalDevice
        self.createTextGeometry = CreateTextGeometry(mapSettings: mapSettings)
        fontLoader = FontLoader(metalDevice: metalDevice)
        regularFont = fontLoader.load(fontName: "Roboto-Regular")
        boldFont = fontLoader.load(fontName: "Roboto-ExtraBold")
        robotoFont = FontBatch(regularFont: regularFont, boldFont: boldFont)
        
        drawText = DrawText(metalDevice: metalDevice)
        textAssembler = TextAssembler(createTextGeometry: createTextGeometry, metalDevice: metalDevice)
        mapLabelsAssembler = MapLabelsAssembler(
            createTextGeometry: createTextGeometry,
            metalDevice: metalDevice,
            frameCounter: frameCounter,
            mapSettings: mapSettings
        )
        
        mapRoadLabelsAssembler = MapRoadLabelsAssembler(
            createTextGeometry: createTextGeometry,
            metalDevice: metalDevice,
            frameCounter: frameCounter
        )
    }
}
