//
//  Pipelines.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class Pipelines {
    private(set) var polygonPipeline: PolygonPipeline!
    private(set) var textPipeline: TextPipeline!
    private(set) var basePipeline: BasePipeline!
    private(set) var labelsPipeline: LabelsPipeline!
    private(set) var transformToScreenPipeline: TransformWorldToScreenPositionPipeline!
 
    init(metalDevice: MTLDevice) {
        // Create the render pipeline
        guard let library = metalDevice.makeDefaultLibrary() else {
            print("Failed to create library")
            return
        }

        polygonPipeline = PolygonPipeline(metalDevice: metalDevice, library: library)
        textPipeline = TextPipeline(metalDevice: metalDevice, library: library)
        basePipeline = BasePipeline(metalDevice: metalDevice, library: library)
        labelsPipeline = LabelsPipeline(metalDevice: metalDevice, library: library)
        transformToScreenPipeline = TransformWorldToScreenPositionPipeline(metalDevice: metalDevice, library: library)
    }
}
