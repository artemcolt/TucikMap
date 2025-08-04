//
//  CameraGlobeView.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class CameraGlobeView : Camera {
    private(set) var globeRotation: Float   = 0
    private(set) var globeRadius: Float     = 0
    
    override func nearAndFar() -> SIMD2<Float> {
        let near: Float         = 0.1
        let far: Float          = 3.0
        return SIMD2<Float>(near, far)
    }
    
    override func updateMap(view: MTKView, size: CGSize) {
        mapZoom         = max(0, min(mapZoom, Settings.zoomLevelMax))
        cameraDistance  = Settings.nullZoomCameraDistance / pow(2.0, mapZoom.truncatingRemainder(dividingBy: 1))
        mapZoomState.update(zoomLevelFloat: mapZoom)
        
        // Compute camera position based on distance and orientation
        let forward         = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition  = targetPosition + forward * cameraDistance
        mapPanning.y    = max(min(mapPanning.y, 1.0), -1.0)
        
        let mapSize     = Double(Settings.mapSize) // размер карты снизу и доверху
        let panY        = mapPanning.y // 0 в центре карты, на половине пути
        let mercY       = -panY / mapSize * 2.0 * Double.pi
        let latitude    = 2.0 * atan(exp(mercY)) - Double.pi / 2
        globeRotation   = Float(latitude)
        globeRadius     = Settings.nullZoomGlobeRadius * mapZoomState.powZoomLevel
        
        super.updateMap(view: view, size: size)
    }
}
