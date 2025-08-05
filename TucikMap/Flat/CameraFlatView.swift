//
//  CameraFlatView.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class CameraFlatView : Camera {
    override var mapSize: Float { get { return flatMapSize } }
    
    private var flatMapSize: Float = Settings.baseFlatMapSize
    
    func applyDistortion(distortion: Float) {
        flatMapSize = Settings.baseFlatMapSize * distortion
    }
    
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
}
