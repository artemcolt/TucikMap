//
//  Camera.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import SwiftUI
import MetalKit

class CameraStorage {
    var flatView: CameraFlatView {
        get {
            return _flatView!
        }
    }
    
    var globeView: CameraGlobeView {
        get {
            return _globeView!
        }
    }
    
    var currentView: Camera {
        get {
            switch mapModeStorage.mapMode {
            case .flat:
                return flatView
            case .globe:
                return globeView
            }
        }
    }
    
    let controlsDelegate                    : ControlsDelegate
    private let cameraContext               : CameraContext
    private let mapModeStorage              : MapModeStorage
    private let mapZoomState                : MapZoomState
    private let drawingFrameRequester       : DrawingFrameRequester
    private let mapCadDisplayLoop           : MapCADisplayLoop
    private var _flatView                   : CameraFlatView?
    private var _globeView                  : CameraGlobeView?
    
    init(mapModeStorage: MapModeStorage,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop, mapSettings: MapSettings) {
        self.controlsDelegate       = ControlsDelegate()
        self.mapModeStorage         = mapModeStorage
        self.mapZoomState           = mapZoomState
        self.drawingFrameRequester  = drawingFrameRequester
        self.mapCadDisplayLoop      = mapCadDisplayLoop
        self.cameraContext          = CameraContext()
        
        _flatView = CameraFlatView(mapZoomState: mapZoomState,
                                   drawingFrameRequester: drawingFrameRequester,
                                   mapCadDisplayLoop: mapCadDisplayLoop,
                                   cameraContext: cameraContext,
                                   mapSettings: mapSettings)
        
        _globeView = CameraGlobeView(mapZoomState: mapZoomState,
                                     drawingFrameRequester: drawingFrameRequester,
                                     mapCadDisplayLoop: mapCadDisplayLoop,
                                     cameraContext: cameraContext,
                                     mapSettings: mapSettings)
    }
    
    // Handle single-finger pan gesture for target translation
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        currentView.handlePan(gesture)
    }
    
    // Handle two-finger rotation gesture for yaw
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        currentView.handleRotation(gesture)
    }
    
    // Handle two-finger pan gesture for pitch and zoom
    @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        currentView.handleTwoFingerPan(gesture)
    }
    
    // Handle pinch gesture for camera distance (zoom)
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        currentView.handlePinch(gesture)
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        currentView.handleDoubleTap(gesture)
    }
}
