//
//  ScrCollDetStorage.swift
//  TucikMap
//
//  Created by Artem on 8/8/25.
//

import MetalKit

class ScrCollDetStorage {
    var flat: ScreenCollisionsDetectorFlat {
        get {
            return _flat!
        }
    }
    
    var globe: ScreenCollisionsDetectorGlobe {
        get {
            return _globe!
        }
    }
    
    var currentView: ScreenCollisionsDetector {
        get {
            switch mapModeStorage.mapMode {
            case .flat:
                return flat
            case .globe:
                return globe
            }
        }
    }
    
    private var _flat               : ScreenCollisionsDetectorFlat?
    private var _globe              : ScreenCollisionsDetectorGlobe?
    private let mapModeStorage      : MapModeStorage
    
    init(mapModeStorage: MapModeStorage,
         metalDevice: MTLDevice,
         library: MTLLibrary,
         metalCommandQueue: MTLCommandQueue,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         frameCounter: FrameCounter) {
        self.mapModeStorage = mapModeStorage
        
        _flat = ScreenCollisionsDetectorFlat(metalDevice: metalDevice,
                                             library: library,
                                             metalCommandQueue: metalCommandQueue,
                                             mapZoomState: mapZoomState,
                                             drawingFrameRequester: drawingFrameRequester,
                                             frameCounter: frameCounter)
        
        _globe = ScreenCollisionsDetectorGlobe(metalDevice: metalDevice,
                                               library: library,
                                               metalCommandQueue: metalCommandQueue,
                                               mapZoomState: mapZoomState,
                                               drawingFrameRequester: drawingFrameRequester,
                                               frameCounter: frameCounter)
    }
}
