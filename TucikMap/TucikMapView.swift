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
    private let mapSettings: MapSettings
    private let addPitchSlider: Bool
    
    init(mapSettings: MapSettings) {
        self.mapSettings = mapSettings
        self.addPitchSlider = mapSettings.getMapCameraSettings().addPitchSlider
    }
    
    func makeUIView(context: Context) -> MTKView {
        let bgColor = mapSettings.getMapCommonSettings().getMapStyle().getMapBaseColors().getBackgroundColor()
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: bgColor[0], green: bgColor[1], blue: bgColor[2], alpha: bgColor[3])
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = mapSettings.getMapCommonSettings().getPreferredFramesPerSecond()
        
        let cameraInputsHandler = context.coordinator.cameraInputsHandler
        let delegate = cameraInputsHandler.controlsDelegate
        
        // Add gesture recognizers
        // Панорамирование
        let singleFingerPan = UIPanGestureRecognizer(target: cameraInputsHandler, action: #selector(cameraInputsHandler.handlePan(_:)))
        singleFingerPan.maximumNumberOfTouches = 1
        singleFingerPan.minimumNumberOfTouches = 1
        singleFingerPan.delegate = delegate
        mtkView.addGestureRecognizer(singleFingerPan)
        
        // Поворот камеру вокруг вектора взгляда
        let rotationGesture = UIRotationGestureRecognizer(target: cameraInputsHandler, action: #selector(cameraInputsHandler.handleRotation(_:)))
        rotationGesture.delegate = delegate
        mtkView.addGestureRecognizer(rotationGesture)
        
        // наклон камеры двумя пальцами
        if mapSettings.getMapCameraSettings().getUseTwoFingerPinchGesture() {
            let twoFingerGesture = UIPanGestureRecognizer(target: cameraInputsHandler, action: #selector(cameraInputsHandler.handleTwoFingerPan(_:)))
            twoFingerGesture.minimumNumberOfTouches = 2
            twoFingerGesture.maximumNumberOfTouches = 2
            twoFingerGesture.delegate = delegate
            mtkView.addGestureRecognizer(twoFingerGesture)
        }
        
        // Add pinch gesture recognizer for zoom
        // Зумирование камеры к карте
        let pinchGesture = UIPinchGestureRecognizer(target: cameraInputsHandler, action: #selector(cameraInputsHandler.handlePinch(_:)))
        pinchGesture.delegate = delegate
        mtkView.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: cameraInputsHandler, action: #selector(cameraInputsHandler.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2 // Устанавливаем количество касаний для двойного клика
        doubleTapGesture.delegate = delegate
        mtkView.addGestureRecognizer(doubleTapGesture)
        
        addPitchSlider(mtkView, cameraInputsHandler)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mapSettings: mapSettings)
    }
    
    private func addPitchSlider(_ mtkView: MTKView, _ cameraInputsHandler: CameraInputsHandler) {
        if addPitchSlider == false { return }
        
        let minPitch = mapSettings.getMapCameraSettings().getMinCameraPitch()
        let maxPitch = mapSettings.getMapCameraSettings().getMaxCameraPitch()
        
        // Add vertical slider for handling tilt (replacing two-finger gesture)
        let tiltSlider = UISlider()
        tiltSlider.translatesAutoresizingMaskIntoConstraints = false
        tiltSlider.minimumValue = minPitch
        tiltSlider.maximumValue = maxPitch
        tiltSlider.value = maxPitch - cameraInputsHandler.cameraPitch
        tiltSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        tiltSlider.addTarget(cameraInputsHandler, action: #selector(cameraInputsHandler.handleTiltSlider(_:)), for: .valueChanged)
        mtkView.addSubview(tiltSlider)
        
        // Constraints for bottom-left positioning
        NSLayoutConstraint.activate([
            tiltSlider.leftAnchor.constraint(equalTo: mtkView.leftAnchor, constant: -20),
            tiltSlider.bottomAnchor.constraint(equalTo: mtkView.bottomAnchor, constant: -20),
            tiltSlider.widthAnchor.constraint(equalToConstant: 100), // Thickness
            tiltSlider.heightAnchor.constraint(equalToConstant: 150) // Length
        ])
    }
}
