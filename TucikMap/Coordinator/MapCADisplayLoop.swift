//
//  MapCADisplayLoop.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

class MapCADisplayLoop {
    private let camera: Camera
    private let frameCounter: FrameCounter
    private let assembledMapUpdater: AssembledMapUpdater
    private let renderFrameCount: RenderFrameCount
    private let screenCollisionDetector: ScreenCollisionsDetector
    
    private var recomputeIntersectionsFlag = true
    private var loopCount: UInt64 = 0
    private var computeIntersectionsEvery: UInt64 = Settings.refreshLabelsIntersectionsEveryNDisplayLoop
    
    
    init(camera: Camera,
         frameCounter: FrameCounter,
         renderFrameCount: RenderFrameCount,
         screenCollisionDetector: ScreenCollisionsDetector
    ) {
        self.camera = camera
        self.frameCounter = frameCounter
        self.assembledMapUpdater = camera.assembledMapUpdater
        self.renderFrameCount = renderFrameCount
        self.screenCollisionDetector = screenCollisionDetector
    }
    
    func recomputeIntersections() {
        recomputeIntersectionsFlag = true
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (canComputeIntersectionsNow()) {
            
            if let lastUnifroms = camera.updateBufferedUniform.lastUniforms {
                screenCollisionDetector.evaluateTileGeoLabels(
                    lastUniforms: lastUnifroms,
                    mapPanning: camera.mapPanning,
                )
            }
        }
    }
    
    private func canComputeIntersectionsNow() -> Bool {
        if loopCount % computeIntersectionsEvery == 0 && recomputeIntersectionsFlag {
            recomputeIntersectionsFlag = false
            return true
        }
        return false
    }
}
