//
//  CameraContext.swift
//  TucikMap
//
//  Created by Artem on 7/25/25.
//

class CameraContext {
    var mapPanning: SIMD3<Double>   = SIMD3<Double>(0, 0, 0) // смещение карты
    var mapZoom: Float              = 0
}
