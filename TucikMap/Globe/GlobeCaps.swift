//
//  GlobeCaps.swift
//  TucikMap
//
//  Created by Artem on 8/10/25.
//

import MetalKit
import Foundation  // For math functions like sinh, atan

class GlobeCaps {
    struct MapParams {
        let latitude: Float
        let globeRadius: Float
        let factor: Float
        let fade: Float
    };
    
    private let slices = 60
    
    private let verticesBuffer          : MTLBuffer
    private let colorsBuffer            : MTLBuffer
    private let vertexCount             : Int
    private let cameraGlobeView         : CameraGlobeView
    private let mapZoomState            : MapZoomState
    private let globeCapsPipeline       : GlobeCapsPipeline
    private let startZ                  : Float
    private let endZ                    : Float
    
    
    init(metalDevice: MTLDevice,
         mapSettings: MapSettings,
         cameraGlobeView: CameraGlobeView,
         mapZoomState: MapZoomState,
         globeCapsPipeline: GlobeCapsPipeline) {
        self.cameraGlobeView = cameraGlobeView
        self.mapZoomState = mapZoomState
        self.globeCapsPipeline = globeCapsPipeline
        self.startZ = mapSettings.getMapCommonSettings().getFadeCapsStartZ()
        self.endZ = mapSettings.getMapCommonSettings().getFadeCapsEndZ()
        
        let nullZoomGlobeRadius = mapSettings.getMapCommonSettings().getNullZoomGlobeRadius()
        let globeRadius = nullZoomGlobeRadius
        let globeCenter = SIMD3<Float>(0, 0, 0)
        
        let pi = Float.pi
        let lat_max_rad = 2 * (atan(exp(pi)) - pi / 4)
        let cos_cutoff = cos(lat_max_rad)
        let sin_cutoff_n = sin(lat_max_rad)
        let sin_cutoff_s = -sin(lat_max_rad)
        
        let pole_n = SIMD3<Float>(0, globeRadius, 0)
        let pole_s = SIMD3<Float>(0, -globeRadius, 0)
        
        var vertices: [SIMD3<Float>] = []
        
        // North cap
        for i in 0..<slices {
            let theta1 = 2 * pi * Float(i) / Float(slices)
            let theta2 = 2 * pi * Float((i + 1) % slices) / Float(slices)
            
            let p1 = globeCenter + SIMD3<Float>(
                globeRadius * cos_cutoff * cos(theta1),
                globeRadius * sin_cutoff_n,
                globeRadius * cos_cutoff * sin(theta1)
            )
            
            let p2 = globeCenter + SIMD3<Float>(
                globeRadius * cos_cutoff * cos(theta2),
                globeRadius * sin_cutoff_n,
                globeRadius * cos_cutoff * sin(theta2)
            )
            
            // Reversed order for back-facing: pole, p2, p1
            vertices.append(pole_n)
            vertices.append(p2)
            vertices.append(p1)
        }
        
        let northPoleColor = mapSettings.getMapBaseColors().getNorthPoleColor()
        let southPoleColor = mapSettings.getMapBaseColors().getSouthPoleColor()
        let northPoleColors = Array(repeating: northPoleColor, count: vertices.count)
        let southPoleColors = Array(repeating: southPoleColor, count: vertices.count)
        let colors = northPoleColors + southPoleColors
        
        // South cap
        for i in 0..<slices {
            let theta1 = 2 * pi * Float(i) / Float(slices)
            let theta2 = 2 * pi * Float((i + 1) % slices) / Float(slices)
            
            let p1 = globeCenter + SIMD3<Float>(
                globeRadius * cos_cutoff * cos(theta1),
                globeRadius * sin_cutoff_s,
                globeRadius * cos_cutoff * sin(theta1)
            )
            
            let p2 = globeCenter + SIMD3<Float>(
                globeRadius * cos_cutoff * cos(theta2),
                globeRadius * sin_cutoff_s,
                globeRadius * cos_cutoff * sin(theta2)
            )
            
            // Reversed order for back-facing: pole, p1, p2 (original was flipped, so reversing it back but overall reverse for culling)
            vertices.append(pole_s)
            vertices.append(p1)
            vertices.append(p2)
        }
        
        self.vertexCount = vertices.count
        self.verticesBuffer = metalDevice.makeBuffer(bytes: vertices, length: MemoryLayout<SIMD3<Float>>.stride * vertices.count)!
        self.colorsBuffer = metalDevice.makeBuffer(bytes: colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count)!
    }
    
    private func drawCaps(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer, mapParams: MapParams) {
        var mapParams = mapParams
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBytes(&mapParams, length: MemoryLayout<MapParams>.stride, index: 3)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
    
    func drawCapsFor(renderEncoder: MTLRenderCommandEncoder, uniformsBuffer: MTLBuffer) {
        let camera = cameraGlobeView
        let currentZ = mapZoomState.zoomLevelFloat
        let interpolation: Float = 1.0 - max(0, min(1, (currentZ - startZ) / (endZ - startZ)))
        let mapParams = GlobeCaps.MapParams(latitude: camera.latitude,
                                            globeRadius: camera.globeRadius,
                                            factor: mapZoomState.powZoomLevel,
                                            fade: interpolation)
        if interpolation != 0 {
            globeCapsPipeline.selectPipeline(renderEncoder: renderEncoder)
            drawCaps(renderEncoder: renderEncoder,
                     uniformsBuffer: uniformsBuffer,
                     mapParams: mapParams)
        }
    }
}
