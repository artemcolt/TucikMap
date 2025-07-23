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
    private let drawingFrameRequester: DrawingFrameRequester
    
    private var forceUpdateStatesFlag      = true
    
    private var evaluateScreenDataFlag     = true
    
    private var loopCount: UInt64 = 0
    private var computeIntersectionsEvery: UInt64 = Settings.refreshLabelsIntersectionsEveryNDisplayLoop
    
    func checkEvaluateScreenData() -> Bool {
        if evaluateScreenDataFlag {
            evaluateScreenDataFlag = false
            return true
        }
        return false
    }
    
    init(camera: Camera,
         frameCounter: FrameCounter,
         drawingFrameRequester: DrawingFrameRequester,
    ) {
        self.camera = camera
        self.frameCounter = frameCounter
        self.assembledMapUpdater = camera.assembledMapUpdater
        self.drawingFrameRequester = drawingFrameRequester
    }
    
    func forceUpdateStates() {
        forceUpdateStatesFlag = true
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (computeScreenLabelsDeltaCondition() && forceUpdateStatesFlag) {
            forceUpdateStatesFlag       = false
            
            evaluateScreenDataFlag      = true
            
            drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
        }
    }
    
    private func computeScreenLabelsDeltaCondition() -> Bool {
        if loopCount % computeIntersectionsEvery == 0 {
            return true
        }
        return false
    }
}
