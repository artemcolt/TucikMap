//
//  RenderFrameCount.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//


class RenderFrameCount {
    private var renderNextFramesCount = 0
    
    func renderNextNFrames(_ n: Int) {
        renderNextFramesCount = n
    }
    
    func isRedrawNeeded() -> Bool {
        if renderNextFramesCount > 0 {
            renderNextFramesCount -= 1
            return true
        }
        return false
    }
}
