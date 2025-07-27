//
//  CameraFlatView.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class CameraFlatView : Camera {
    override func nearAndFar() -> SIMD2<Float> {
        let halfPi              = Float.pi / 2
        let pitchAngle: Float   = cameraPitch
        let pitchNormalized     = pitchAngle / halfPi
        let nearFactor          = sqrt(pitchNormalized)
        let farFactor           = pitchAngle * Settings.farPlaneIncreaseFactor
        
        let delta: Float        = 1.0
        let near: Float         = cameraDistance - delta - nearFactor * cameraDistance
        var far: Float          = cameraDistance + delta + farFactor  * cameraDistance
        far += 5
        
        return SIMD2<Float>(near, far)
    }
    
    override func updateMap(view: MTKView, size: CGSize) {
        mapZoom = max(0, min(mapZoom, Settings.zoomLevelMax))
        cameraDistance = Settings.nullZoomCameraDistance / pow(2.0, mapZoom.truncatingRemainder(dividingBy: 1))
        mapZoomState.update(zoomLevelFloat: mapZoom)
        
        // Вернуть в допустимую зону камеру
//        let zoomFactor = Double(pow(2.0, floor(mapZoom)))
//        let visibleHeight = 2.0 * Double(cameraDistance) * Double(tan(Settings.fov / 2.0)) / zoomFactor
//        let targetPositionYMin = Double(-Settings.mapSize) / 2.0 + visibleHeight / 2.0
//        let targetPositionYMax = Double(Settings.mapSize) / 2.0  - visibleHeight / 2.0
//        if (mapPanning.y < targetPositionYMin) {
//            mapPanning.y = targetPositionYMin
//        } else if (mapPanning.y > targetPositionYMax) {
//            mapPanning.y = targetPositionYMax
//        }
        
        // Compute camera position based on distance and orientation
        forward = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition = targetPosition + forward * cameraDistance
        
        super.updateMap(view: view, size: size)
    }
}
