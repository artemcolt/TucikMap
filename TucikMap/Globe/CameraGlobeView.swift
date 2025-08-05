//
//  CameraGlobeView.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class CameraGlobeView : Camera {
    override var mapSize: Float { get { return Settings.globeMapSize } }
    
    override func nearAndFar() -> SIMD2<Float> {
        let near: Float         = 0.1
        let far: Float          = 3.0
        return SIMD2<Float>(near, far)
    }
}
