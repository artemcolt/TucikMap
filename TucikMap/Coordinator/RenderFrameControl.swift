//
//  NeedRendering.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

import MetalKit
import Foundation

class RenderFrameControl {
    private var displayLink: CADisplayLink?
    private weak var mtkView: MTKView?
    private let mapCADisplayLoop: MapCADisplayLoop
    private let drawingFrameRequester: DrawingFrameRequester
    private let mapSettings: MapSettings
    
    init(mapCADisplayLoop: MapCADisplayLoop, drawingFrameRequester: DrawingFrameRequester, mapSettings: MapSettings) {
        self.mapSettings = mapSettings
        self.mapCADisplayLoop = mapCADisplayLoop
        self.drawingFrameRequester = drawingFrameRequester
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
        self.displayLink?.isPaused = true // Start paused
        self.displayLink?.preferredFramesPerSecond = mapSettings.getMapCommonSettings().getPreferredFramesPerSecond() // Match MTKView's preferredFramesPerSecond
        self.displayLink?.add(to: .main, forMode: .common)
    }
    
    func updateView(view: MTKView) {
        self.mtkView = view
        self.displayLink?.isPaused = false
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        drawingFrameRequester.renderNextNFrames(maxBuffersInFlight)
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    @objc func displayLinkUpdate() {
        mapCADisplayLoop.displayLoop()
        
        let forceRenderOnDisplayUpdate = mapSettings.getMapCommonSettings().getForceRenderOnDisplayUpdate()
        if drawingFrameRequester.isRedrawNeeded() || forceRenderOnDisplayUpdate {
            mtkView?.setNeedsDisplay()
        }
    }
}
