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
    
    init(mapCADisplayLoop: MapCADisplayLoop, drawingFrameRequester: DrawingFrameRequester) {
        self.mapCADisplayLoop = mapCADisplayLoop
        self.drawingFrameRequester = drawingFrameRequester
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
        self.displayLink?.isPaused = true // Start paused
        self.displayLink?.preferredFramesPerSecond = Settings.preferredFramesPerSecond // Match MTKView's preferredFramesPerSecond
        self.displayLink?.add(to: .main, forMode: .common)
    }
    
    func updateView(view: MTKView) {
        self.mtkView = view
        self.displayLink?.isPaused = false
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    @objc func displayLinkUpdate() {
        mapCADisplayLoop.displayLoop()
        
        if drawingFrameRequester.isRedrawNeeded() || Settings.forceRenderOnDisplayUpdate {
            mtkView?.setNeedsDisplay()
        }
    }
}
