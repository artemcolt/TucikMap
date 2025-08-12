//
//  MapMoveSettings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import SwiftUI
import MetalKit

struct MapMoveSettings {
    let enabled: Bool
    let z: Float
    let latLon: SIMD2<Double> //55.74958790780624, 37.62346867711091
    
    func initMove(camera: Camera, view: MTKView, size: CGSize) {
        if enabled {
            camera.moveTo(lat: latLon.x,
                          lon: latLon.y,
                          zoom: z,
                          view: view,
                          size: size)
        }
    }
}
