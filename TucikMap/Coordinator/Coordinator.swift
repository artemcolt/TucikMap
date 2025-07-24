//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit

class Coordinator: NSObject, MTKViewDelegate {
    var parent: MetalView
    
    private var metalDevice                 : MTLDevice
    private var metalCommandQueue           : MTLCommandQueue
    private var semaphore                   : DispatchSemaphore
    
    private var determineFeatureStyle   : DetermineFeatureStyle
    private var frameCounter            : FrameCounter
    private var drawingFrameRequester   : DrawingFrameRequester!
    private var textTools               : TextTools
    private var mapCadDisplayLoop       : MapCADisplayLoop
    
    private var metalTilesStorage       : MetalTilesStorage
    
    var flatMode: FlatMode
    
    init(_ parent: MetalView) {
        self.parent = parent
        
        
        let device              = MTLCreateSystemDefaultDevice()!
        metalDevice             = device
        metalCommandQueue       = device.makeCommandQueue()!
        semaphore               = DispatchSemaphore(value: Settings.maxBuffersInFlight)
        
        drawingFrameRequester   = DrawingFrameRequester()
        frameCounter            = FrameCounter()
        mapCadDisplayLoop       = MapCADisplayLoop(frameCounter: frameCounter,
                                                   drawingFrameRequester: drawingFrameRequester)
        determineFeatureStyle   = DetermineFeatureStyle()
        textTools               = TextTools(metalDevice: metalDevice, frameCounter: frameCounter)
        metalTilesStorage       = MetalTilesStorage(determineStyle: determineFeatureStyle,
                                                    metalDevice: metalDevice,
                                                    textTools: textTools)
        
        flatMode                = FlatMode(metalDevice: metalDevice,
                                           metalCommandQueue: metalCommandQueue,
                                           frameCounter: frameCounter,
                                           drawingFrameRequester: drawingFrameRequester,
                                           textTools: textTools,
                                           metalTilesStorage: metalTilesStorage,
                                           mapCadDisplayLoop: mapCadDisplayLoop)
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        flatMode.mtkView(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            self.semaphore.signal()
            return
        }
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.semaphore.signal()
        }
        
        flatMode.draw(in: view,
                      renderPassDescriptor: renderPassDescriptor,
                      commandBuffer: commandBuffer)
        
        commandBuffer.present(drawable)
        frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
}
