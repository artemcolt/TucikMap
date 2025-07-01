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
    private let screenCollisionsDetector: ScreenCollisionsDetector
    private let renderFrameCount: RenderFrameCount
    
    private var loopCount: UInt64 = 0
    private var computeIntersectionsEvery: UInt64 = Settings.refreshLabelsIntersectionsEveryNDisplayLoop
    
    init(camera: Camera,
         frameCounter: FrameCounter,
         assembledMapUpdater: AssembledMapUpdater,
         screenCollisionsDetector: ScreenCollisionsDetector,
         renderFrameCount: RenderFrameCount
    ) {
        self.camera = camera
        self.frameCounter = frameCounter
        self.assembledMapUpdater = assembledMapUpdater
        self.screenCollisionsDetector = screenCollisionsDetector
        self.renderFrameCount = renderFrameCount
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (canComputeIntersectionsNow()) {
            if let lastUniforms = camera.updateBufferedUniform.lastUniforms {
                screenCollisionsDetector.evaluateTilesData(
                    tiles: assembledMapUpdater.assembledMap.tiles,
                    lastUniforms: lastUniforms,
                    mapPanning: camera.mapPanning
                )
                renderFrameCount.renderNextNFrames(3)
            }
        }
    }
    
    private func canComputeIntersectionsNow() -> Bool {
        if loopCount % computeIntersectionsEvery == 0 {
            return true
        }
        return false
    }
}
