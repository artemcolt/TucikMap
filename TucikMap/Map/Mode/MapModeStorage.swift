//
//  MapModeStorage.swift
//  TucikMap
//
//  Created by Artem on 7/25/25.
//

import MetalKit

class MapModeStorage {
    var mapMode: MapMode = .globe
    let mapZoomState: MapZoomState
    private(set) var transition: Float = 0
    var switchModeFlag: Bool = false
    
    init(mapZoomState: MapZoomState) {
        self.mapZoomState = mapZoomState
    }
    
    func switchState() {
        switchModeFlag = true
    }
    
    func updateTransition() {
        let transitionZoomEnd   = Settings.globeToPlaneZoomEnd
        let transitionZoomStart = Settings.globeToPlaneZoomStart
        let currentZoom         = mapZoomState.zoomLevelFloat
        transition              = max(0.0, min(1.0, (currentZoom - transitionZoomStart) / (transitionZoomEnd - transitionZoomStart)))
    }
    
    func modeSwitching(view: MTKView) -> Bool {
        let transitionZoomEnd   = Settings.globeToPlaneZoomEnd
        let currentZoom         = mapZoomState.zoomLevelFloat
        
        if currentZoom <= transitionZoomEnd && mapMode != .globe {
            mapMode = .globe
            return true
        } else if currentZoom >= transitionZoomEnd && mapMode != .flat {
            mapMode = .flat
            return true
        }
        return false
    }
}
