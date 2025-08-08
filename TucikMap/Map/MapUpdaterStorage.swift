//
//  MapUpdaterStorage.swift
//  TucikMap
//
//  Created by Artem on 7/26/25.
//

import MetalKit

class MapUpdaterStorage {
    var flat: MapUpdaterFlat {
        get {
            return _flat!
        }
    }
    
    var globe: MapUpdaterGlobe {
        get {
            return _globe!
        }
    }
    
    var currentView: MapUpdater {
        get {
            switch mapModeStorage.mapMode {
            case .flat:
                return flat
            case .globe:
                return globe
            }
        }
    }
    
    private var _flat               : MapUpdaterFlat?
    private var _globe              : MapUpdaterGlobe?
    private let mapModeStorage      : MapModeStorage
    private let mapUpdaterContext   : MapUpdaterContext
    
    init(mapModeStorage: MapModeStorage,
         mapZoomState: MapZoomState,
         metalDevice: MTLDevice,
         camera: CameraStorage,
         textTools: TextTools,
         drawingFrameRequester: DrawingFrameRequester,
         frameCounter: FrameCounter,
         metalTilesStorage: MetalTilesStorage,
         mapCadDisplayLoop: MapCADisplayLoop,
         screenCollisionsDetector: ScreenCollisionsDetector,
         updateBufferedUniform: UpdateBufferedUniform,
         globeTexturing: GlobeTexturing,
         mapUpdaterContext: MapUpdaterContext) {
        
        self.mapUpdaterContext  = mapUpdaterContext
        self.mapModeStorage     = mapModeStorage
        
        _flat = MapUpdaterFlat(mapZoomState: mapZoomState,
                               device: metalDevice,
                               camera: camera.flatView,
                               textTools: textTools,
                               drawingFrameRequester: drawingFrameRequester,
                               frameCounter: frameCounter,
                               metalTilesStorage: metalTilesStorage,
                               mapCadDisplayLoop: mapCadDisplayLoop,
                               mapModeStorage: mapModeStorage,
                               mapUpdaterContext: mapUpdaterContext,
                               screenCollisionsDetector: screenCollisionsDetector,
                               updateBufferedUniform: updateBufferedUniform)
        
        _globe = MapUpdaterGlobe(mapZoomState: mapZoomState,
                                 device: metalDevice,
                                 camera: camera.globeView,
                                 textTools: textTools,
                                 drawingFrameRequester: drawingFrameRequester,
                                 frameCounter: frameCounter,
                                 metalTilesStorage: metalTilesStorage,
                                 mapCadDisplayLoop: mapCadDisplayLoop,
                                 mapModeStorage: mapModeStorage,
                                 mapUpdaterContext: mapUpdaterContext,
                                 screenCollisionsDetector: screenCollisionsDetector,
                                 updateBufferedUniform: updateBufferedUniform,
                                 globeTexturing: globeTexturing)
    }
}
