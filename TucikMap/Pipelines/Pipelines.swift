//
//  Pipelines.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class Pipelines {
    let library: MTLLibrary
    private(set) var polygonPipeline: PolygonPipeline!
    private(set) var textPipeline: TextPipeline!
    private(set) var basePipeline: BasePipeline!
    private(set) var labelsPipeline: LabelsPipeline!
 
    init(metalDevice: MTLDevice) {
        // Create the render pipeline
        library = metalDevice.makeDefaultLibrary()!

        polygonPipeline = PolygonPipeline(metalDevice: metalDevice, library: library)
        textPipeline = TextPipeline(metalDevice: metalDevice, library: library)
        basePipeline = BasePipeline(metalDevice: metalDevice, library: library)
        labelsPipeline = LabelsPipeline(metalDevice: metalDevice, library: library)
    }
}
