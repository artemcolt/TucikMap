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
            return _flat
        }
    }
    
    var globe: ScreenCollisionsDetectorGlobe {
        get {
            return _globe
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
    
    private let _flat               : ScreenCollisionsDetectorFlat
    private let _globe              : ScreenCollisionsDetectorGlobe
    private let mapModeStorage      : MapModeStorage
    
    init(mapModeStorage: MapModeStorage,
         metalDevice: MTLDevice,
         library: MTLLibrary,
         metalCommandQueue: MTLCommandQueue,
         mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         frameCounter: FrameCounter) {
        self.mapModeStorage = mapModeStorage
        
        let computeScreenPositions = ComputeScreenPositions(metalDevice: metalDevice, library: library)
        let handleGeoLabels = HandleGeoLabels(frameCounter: frameCounter,
                                              mapZoomState: mapZoomState)
        let handleRoadLabels = HandleRoadLabels(mapZoomState: mapZoomState, frameCounter: frameCounter)
        
        let onPointsReadyHandlerGlobe = OnPointsReadyHandlerGlobe(drawingFrameRequester: drawingFrameRequester,
                                                                  handleGeoLabels: handleGeoLabels)
        
        let onPointsReadyHandlerFlat = OnPointsReadyHandlerFlat(drawingFrameRequester: drawingFrameRequester,
                                                                handleGeoLabels: handleGeoLabels,
                                                                handleRoadLabels: handleRoadLabels)
        
        _flat = ScreenCollisionsDetectorFlat(metalDevice: metalDevice,
                                             library: library,
                                             metalCommandQueue: metalCommandQueue,
                                             mapZoomState: mapZoomState,
                                             drawingFrameRequester: drawingFrameRequester,
                                             frameCounter: frameCounter,
                                             computeScreenPositions: computeScreenPositions,
                                             handleGeoLabels: handleGeoLabels,
                                             handleRoadLabels: handleRoadLabels,
                                             onPointsReadyHandlerGlobe: onPointsReadyHandlerGlobe,
                                             onPointsReadyHandlerFlat: onPointsReadyHandlerFlat)
        
        _globe = ScreenCollisionsDetectorGlobe(metalDevice: metalDevice,
                                               library: library,
                                               metalCommandQueue: metalCommandQueue,
                                               mapZoomState: mapZoomState,
                                               drawingFrameRequester: drawingFrameRequester,
                                               frameCounter: frameCounter,
                                               computeScreenPositions: computeScreenPositions,
                                               handleGeoLabels: handleGeoLabels,
                                               handleRoadLabels: handleRoadLabels,
                                               onPointsReadyHandlerGlobe: onPointsReadyHandlerGlobe,
                                               onPointsReadyHandlerFlat: onPointsReadyHandlerFlat)
    }
}
