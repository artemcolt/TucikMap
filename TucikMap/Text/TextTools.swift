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
    
    let baseFont: Font
    
    init(metalDevice: MTLDevice, frameCounter: FrameCounter, mapSettings: MapSettings) {
        self.metalDevice = metalDevice
        self.createTextGeometry = CreateTextGeometry(mapSettings: mapSettings)
        fontLoader = FontLoader(metalDevice: metalDevice)
        baseFont = fontLoader.load(fontName: "atlas")
        
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
