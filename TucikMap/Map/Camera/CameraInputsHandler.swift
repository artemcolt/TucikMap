//
//  CameraInputsHandler.swift
//  TucikMap
//
//  Created by Artem on 8/28/25.
//

import SwiftUI

class CameraInputsHandler {
    let controlsDelegate: ControlsDelegate
    private let mapController: MapController
    private let cameraStorage: CameraStorage
    private let maxCameraPitch: Float
    
    var cameraPitch: Float {
        get { cameraStorage.cameraPitch }
    }
    
    init(mapController: MapController, cameraStorage: CameraStorage, mapSettings: MapSettings) {
        self.controlsDelegate = ControlsDelegate()
        self.mapController = mapController
        self.cameraStorage = cameraStorage
        self.maxCameraPitch = mapSettings.getMapCameraSettings().getMaxCameraPitch()
    }
    
    @objc func handleTiltSlider(_ sender: UISlider) {
        mapController.setYawAndPitch(yaw: cameraStorage.currentView.rotationYaw, pitch: maxCameraPitch - Float(sender.value))
    }

    // Handle single-finger pan gesture for target translation
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        cameraStorage.currentView.handlePan(gesture)
    }

    // Handle two-finger rotation gesture for yaw
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        cameraStorage.currentView.handleRotation(gesture)
    }

    // Handle two-finger pan gesture for pitch and zoom
    @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        cameraStorage.currentView.handleTwoFingerPan(gesture)
    }

    // Handle pinch gesture for camera distance (zoom)
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        cameraStorage.currentView.handlePinch(gesture)
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        cameraStorage.currentView.handleDoubleTap(gesture)
    }
}
