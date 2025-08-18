//
//  RenderFrameCount.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

import Foundation

class DrawingFrameRequester {
    private var renderNextFramesCount = 0
    private var renderToTime: TimeInterval = 0
    private let mapSettings: MapSettings
    
    init(mapSettings: MapSettings) {
        self.mapSettings = mapSettings
    }
    
    func renderNextNFrames(_ n: Int) {
        renderNextFramesCount = n
    }
    
    func renderNextNSeconds(_ n: Double) {
        renderToTime = Date().timeIntervalSince1970 + n
    }
    
    func renderNextStep() {
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        renderNextNFrames(maxBuffersInFlight)
    }
    
    func isRedrawNeeded() -> Bool {
        if renderNextFramesCount > 0 || Date().timeIntervalSince1970 <= renderToTime {
            renderNextFramesCount -= 1
            return true
        }
        return false
    }
}
