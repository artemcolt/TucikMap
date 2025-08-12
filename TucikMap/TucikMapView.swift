//
//  MetalView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

// MetalView.swift
import SwiftUI
import MetalKit

struct TucikMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let bgColor = Settings.backgroundColor
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: bgColor[0], green: bgColor[1], blue: bgColor[2], alpha: bgColor[3])
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = Settings.preferredFramesPerSecond
        
        let camera = context.coordinator.cameraStorage
        let delegate = context.coordinator.cameraStorage.controlsDelegate
        
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
        
        let doubleTapGesture = UITapGestureRecognizer(target: camera, action: #selector(camera.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2 // Устанавливаем количество касаний для двойного клика
        doubleTapGesture.delegate = delegate
        mtkView.addGestureRecognizer(doubleTapGesture)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
