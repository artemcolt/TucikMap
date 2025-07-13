//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

struct GeoLabelsWithIntersections {
    let intersections: [Int: [LabelIntersection]]
    let geoLabels: [MetalGeoLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

class ScreenCollisionsDetector {
    private let computeLabelScreen: ComputeLabelScreen
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private var projectPoints: ProjectPoints!
    let handleGeoLabels: HandleGeoLabels
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        handleGeoLabels = HandleGeoLabels(
            frameCounter: frameCounter,
            mapZoomState: mapZoomState,
            renderFrameCount: renderFrameCount
        )
        computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.projectPoints = ProjectPoints(
            computeLabelScreen: computeLabelScreen,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
    }
    
    private func onPointsReady(result: ProjectPoints.Result) {
        handleGeoLabels.onPointsReady(result: result)
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        let result = handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning)
        if result.recallLater {
            return true
        }
        
        var inputComputeScreenVertices = result.inputComputeScreenVertices
        inputComputeScreenVertices.append(contentsOf: Array(
            repeating: InputComputeScreenVertex(location: SIMD2<Float>(1, 1), matrixId: 0),
            count: 100
        ))
        
        projectPoints.project(input: ProjectPoints.ProjectInput(
            modelMatrices: result.modelMatrices,
            uniforms: lastUniforms,
            inputComputeScreenVertices: inputComputeScreenVertices,
            
            metalGeoLabels: result.metalGeoLabels,
            mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
            actualLabelsIds: handleGeoLabels.actualLabelsIds,
            geoLabelsSize: result.geoLabelsSize
        ))
        
        return false
    }
}
