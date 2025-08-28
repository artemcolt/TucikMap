//
//  CameraContext.swift
//  TucikMap
//
//  Created by Artem on 7/25/25.
//

import MetalKit

class CameraContext {
    var mapZoom: Float                      = 0
    var cameraYawQuaternion: simd_quatf     = .init(ix: 0, iy: 0, iz: 0, r: 1)
    var cameraDistance: Float               = 0
    var cameraPitch: Float                  = 0
    var cameraPosition: SIMD3<Float>        = SIMD3<Float>()
    var targetPosition: SIMD3<Float>        = SIMD3<Float>()
    var cameraQuaternion: simd_quatf        = .init(ix: 0, iy: 0, iz: 0, r: 1)
    var rotationYaw: Float                  = 0
}
