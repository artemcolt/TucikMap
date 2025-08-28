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
    
    private let cameraContext               : CameraContext
    private let mapModeStorage              : MapModeStorage
    private var _flatView                   : CameraFlatView?
    private var _globeView                  : CameraGlobeView?
    
    var cameraPitch: Float {
        get { return currentView.cameraPitch }
    }
    
    init(mapModeStorage: MapModeStorage,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop,
         mapSettings: MapSettings) {
        self.mapModeStorage         = mapModeStorage
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
}
