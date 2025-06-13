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
    private let renderFrameCount: RenderFrameCount
    
    init(mapCADisplayLoop: MapCADisplayLoop, renderFrameCount: RenderFrameCount) {
        self.mapCADisplayLoop = mapCADisplayLoop
        self.renderFrameCount = renderFrameCount
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
        self.displayLink?.isPaused = true // Start paused
        self.displayLink?.preferredFramesPerSecond = Settings.preferredFramesPerSecond // Match MTKView's preferredFramesPerSecond
        self.displayLink?.add(to: .main, forMode: .common)
    }
    
    func updateView(view: MTKView) {
        self.mtkView = view
        self.displayLink?.isPaused = false
        renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight)
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    @objc func displayLinkUpdate() {
        mapCADisplayLoop.displayLoop()
        
        if renderFrameCount.isRedrawNeeded() {
            mtkView?.setNeedsDisplay()
        }
    }
}
