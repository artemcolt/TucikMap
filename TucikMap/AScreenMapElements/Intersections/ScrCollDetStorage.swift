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
         frameCounter: FrameCounter,
         mapSettings: MapSettings) {
        self.mapModeStorage = mapModeStorage
        
        let computeScreenPositions = ComputeScreenPositions(metalDevice: metalDevice, library: library)
        let handleGeoLabels = HandleGeoLabels(frameCounter: frameCounter,
                                              mapZoomState: mapZoomState,
                                              mapSettings: mapSettings)
        let handleRoadLabels = HandleRoadLabels(mapZoomState: mapZoomState, frameCounter: frameCounter, mapSettings: mapSettings)
        
        let onPointsReadyHandlerGlobe = OnPointsReadyHandlerGlobe(drawingFrameRequester: drawingFrameRequester,
                                                                  handleGeoLabels: handleGeoLabels,
                                                                  mapSettings: mapSettings)
        
        let onPointsReadyHandlerFlat = OnPointsReadyHandlerFlat(drawingFrameRequester: drawingFrameRequester,
                                                                handleGeoLabels: handleGeoLabels,
                                                                handleRoadLabels: handleRoadLabels,
                                                                mapSettings: mapSettings)
        
        let computeScreenPositionsGlobe = ComputeScreenPositionsGlobe(metalDevice: metalDevice, library: library)
        let computeScreenPositionsFlat = ComputeScreenPositionsFlat(metalDevice: metalDevice, library: library)
        
        let combinedCompSPFlat = CombinedCompSPFlat(metalDevice: metalDevice,
                                                    metalCommandQueue: metalCommandQueue,
                                                    onPointsReadyFlat: onPointsReadyHandlerFlat,
                                                    computeScreenPositionsFlat: computeScreenPositionsFlat,
                                                    mapSettings: mapSettings)
        
        let combinedCompSPGlobe = CombinedCompSPGlobe(metalDevice: metalDevice,
                                                      metalCommandQueue: metalCommandQueue,
                                                      onPointsReadyGlobe: onPointsReadyHandlerGlobe,
                                                      computeScreenPositionsGlobe: computeScreenPositionsGlobe,
                                                      mapSettings: mapSettings)
        
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
                                             onPointsReadyHandlerFlat: onPointsReadyHandlerFlat,
                                             projectPointsFlat: combinedCompSPFlat,
                                             mapSettings: mapSettings)
        
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
                                               onPointsReadyHandlerFlat: onPointsReadyHandlerFlat,
                                               projectPointsGlobe: combinedCompSPGlobe,
                                               mapSettings: mapSettings)
    }
}
