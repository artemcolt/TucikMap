//
//  MetalView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

// MetalView.swift
import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = Settings.preferredFramesPerSecond
        
        let camera = context.coordinator.camera!
        let delegate = context.coordinator.controlsDelegate
        
        // Add gesture recognizers
        let singleFingerPan = UIPanGestureRecognizer(target: camera, action: #selector(camera.handlePan(_:)))
        singleFingerPan.maximumNumberOfTouches = 1
        singleFingerPan.minimumNumberOfTouches = 1
        singleFingerPan.delegate = delegate
        mtkView.addGestureRecognizer(singleFingerPan)
        
        let rotationGesture = UIRotationGestureRecognizer(target: camera, action: #selector(camera.handleRotation(_:)))
        rotationGesture.delegate = delegate
        mtkView.addGestureRecognizer(rotationGesture)
        
        let twoFingerGesture = UIPanGestureRecognizer(target: camera, action: #selector(camera.handleTwoFingerPan(_:)))
        twoFingerGesture.minimumNumberOfTouches = 2
        twoFingerGesture.maximumNumberOfTouches = 2
        twoFingerGesture.delegate = delegate
        mtkView.addGestureRecognizer(twoFingerGesture)
        
        // Add pinch gesture recognizer for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: camera, action: #selector(camera.handlePinch(_:)))
        pinchGesture.delegate = delegate
        mtkView.addGestureRecognizer(pinchGesture)
        
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
