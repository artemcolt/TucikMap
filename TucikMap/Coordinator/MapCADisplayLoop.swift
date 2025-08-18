//
//  MapCADisplayLoop.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

class MapCADisplayLoop {
    private let frameCounter: FrameCounter
    private let drawingFrameRequester: DrawingFrameRequester
    private let mapSettings: MapSettings
    
    private var forceUpdateStatesFlag      = true
    
    private var evaluateScreenDataFlag     = true
    
    private var loopCount: UInt64 = 0
    private var computeIntersectionsEvery: UInt64
    
    func checkEvaluateScreenData() -> Bool {
        if evaluateScreenDataFlag {
            evaluateScreenDataFlag = false
            return true
        }
        return false
    }
    
    init(frameCounter: FrameCounter,
         drawingFrameRequester: DrawingFrameRequester,
         mapSettings: MapSettings
    ) {
        self.mapSettings = mapSettings
        self.frameCounter = frameCounter
        self.drawingFrameRequester = drawingFrameRequester
        
        computeIntersectionsEvery = mapSettings.getMapCommonSettings().getRefreshLabelsIntersectionsEveryNDisplayLoop()
    }
    
    func forceUpdateStates() {
        forceUpdateStatesFlag = true
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (computeScreenLabelsDeltaCondition() && forceUpdateStatesFlag) {
            forceUpdateStatesFlag       = false
            
            evaluateScreenDataFlag      = true
            
            drawingFrameRequester.renderNextNFrames(mapSettings.getMapCommonSettings().getMaxBuffersInFlight())
        }
    }
    
    private func computeScreenLabelsDeltaCondition() -> Bool {
        if loopCount % computeIntersectionsEvery == 0 {
            return true
        }
        return false
    }
}
