//
//  SwitchMapMode.swift
//  TucikMap
//
//  Created by Artem on 8/5/25.
//

import SwiftUI
import MetalKit

class SwitchMapMode {
    private var mapModeStorage: MapModeStorage
    private var cameraStorage: CameraStorage
    private var mapZoomState: MapZoomState
    private var mapSettings: MapSettings
    private(set) var switchModeFlag: Bool = false
    private(set) var transition: Float = 0
    
    init(mapModeStorage: MapModeStorage, cameraStorage: CameraStorage, mapZoomState: MapZoomState, mapSettings: MapSettings) {
        self.mapModeStorage = mapModeStorage
        self.cameraStorage = cameraStorage
        self.mapZoomState = mapZoomState
        self.mapSettings = mapSettings
    }
    
    func switchingMapMode(view: MTKView) -> Bool {
        let globeToPlaneZoomEnd = mapSettings.getMapCommonSettings().getGlobeToPlaneZoomEnd()
        let globeToPlaneZoomStart = mapSettings.getMapCommonSettings().getGlobeToPlaneZoomStart()
        let transitionZoomEnd   = globeToPlaneZoomEnd
        let transitionZoomStart = globeToPlaneZoomStart
        let currentZoom         = mapZoomState.zoomLevelFloat
        transition              = max(0.0, min(1.0, (currentZoom - transitionZoomStart) / (transitionZoomEnd - transitionZoomStart)))
        
        if currentZoom < transitionZoomEnd && mapModeStorage.mapMode != .globe {
            switchModeFlag = true
        } else if currentZoom >= transitionZoomEnd && mapModeStorage.mapMode != .flat {
            switchModeFlag = true
        }
        
        if switchModeFlag {
            switchModeFlag = false
            let flatCam = cameraStorage.flatView
            let globeCam = cameraStorage.globeView
            
            switch mapModeStorage.mapMode {
            case .flat:
                mapModeStorage.mapMode = .globe
                let halfFlatMapSize = Double(flatCam.mapSize) / 2.0
                let halfGlobeMapSize = Double(globeCam.mapSize) / 2.0
                let flatPanning = flatCam.mapPanning
                let globePanX = flatPanning.x / halfFlatMapSize * halfGlobeMapSize
                let globePanY = flatPanning.y / halfFlatMapSize * halfGlobeMapSize
                //print("globePanX \(globePanX) globePanY \(globePanY)")
                
                globeCam.mapPanning = SIMD3<Double>(globePanX, globePanY, 0)
                globeCam.updateMap(view: view, size: view.drawableSize)
                return true
            case .globe:
                cameraStorage.flatView.applyDistortion(distortion: globeCam.distortion)
                
                let halfFlatMapSize = Double(flatCam.mapSize) / 2.0
                mapModeStorage.mapMode = .flat
                
                let globePanning = globeCam.mapPanning
                let flatPanX = globePanning.x * 2.0 * halfFlatMapSize
                let flatPanY = globePanning.y * 2.0 * halfFlatMapSize
                
                flatCam.mapPanning = SIMD3<Double>(flatPanX, flatPanY, 0)
                flatCam.updateMap(view: view, size: view.drawableSize)
                return true
            }
        }
        return false
    }
}
