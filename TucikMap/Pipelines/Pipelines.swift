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
    private(set) var spacePipeline: SpacePipeline!
    private(set) var texturePipeline: TexturePipeline!
    private(set) var globeLabelsPipeline: GlobeLabelsPipeline!
    private(set) var globeGlowingPipeline: GlobeGlowingPipeline!
    private(set) var globeCapsPipeline: GlobeCapsPipeline!
    private(set) var globeGeomPipeline: GlobeGeomPipeline!
    private(set) var postProcessing: DrawTextureOnScreenPipeline!
    private(set) var textureAdderPipeline: TextureAdderPipeline!
    private(set) var globeMarkersPipeline: GlobeMarkersPipeline!
    private(set) var markersPipeline: MarkersPipeline!
 
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
        spacePipeline = SpacePipeline(metalDevice: metalDevice, library: library)
        globeGlowingPipeline = GlobeGlowingPipeline(metalDevice: metalDevice, library: library)
        globeCapsPipeline = GlobeCapsPipeline(metalDevice: metalDevice, library: library)
        globeGeomPipeline = GlobeGeomPipeline(metalDevice: metalDevice, library: library)
        postProcessing = DrawTextureOnScreenPipeline(metalDevice: metalDevice, library: library)
        textureAdderPipeline = TextureAdderPipeline(metalDevice: metalDevice, library: library)
        globeMarkersPipeline = GlobeMarkersPipeline(metalDevice: metalDevice, library: library)
        markersPipeline = MarkersPipeline(metalDevice: metalDevice, library: library)
    }
}
