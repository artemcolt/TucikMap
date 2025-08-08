//
//  Pipelines.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class Pipelines {
    let library: MTLLibrary
    private(set) var polygon3dPipeline: Polygon3dPipeline!
    private(set) var polygonPipeline: PolygonPipeline!
    private(set) var textPipeline: TextPipeline!
    private(set) var basePipeline: BasePipeline!
    private(set) var labelsPipeline: LabelsPipeline!
    private(set) var roadLabelPipeline: RoadLabelPipeline!
    private(set) var globePipeline: GlobePipeline!
    private(set) var texturePipeline: TexturePipeline!
    private(set) var globeLabelsPipeline: GlobeLabelsPipeline!
 
    init(metalDevice: MTLDevice) {
        // Create the render pipeline
        library = metalDevice.makeDefaultLibrary()!

        polygon3dPipeline = Polygon3dPipeline(metalDevice: metalDevice, library: library)
        polygonPipeline = PolygonPipeline(metalDevice: metalDevice, library: library)
        textPipeline = TextPipeline(metalDevice: metalDevice, library: library)
        basePipeline = BasePipeline(metalDevice: metalDevice, library: library)
        labelsPipeline = LabelsPipeline(metalDevice: metalDevice, library: library)
        roadLabelPipeline = RoadLabelPipeline(metalDevice: metalDevice, library: library)
        globePipeline = GlobePipeline(metalDevice: metalDevice, library: library)
        texturePipeline = TexturePipeline(metalDevice: metalDevice, library: library)
        globeLabelsPipeline = GlobeLabelsPipeline(metalDevice: metalDevice, library: library)
    }
}
