//
//  UpdateBufferedUniform.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import SwiftUI
import MetalKit
import Foundation

class UpdateBufferedUniform {
    
    private var currentBufferIndex      = -1
    private let halfPi                  = Float.pi / 2
    private let maxLatitudeRadians      : Float
    
    private(set) var lastUniforms       : Uniforms?
    private(set) var lastViewportSize   : SIMD2<Float>!
    
    // Triple buffering for uniforms
    private(set) var uniformBuffers     : [MTLBuffer] = []
    private let frameCounter            : FrameCounter
    private let maxBuffersInFlight      : Int
    private let device                  : MTLDevice
    private let mapZoomState            : MapZoomState
    private let cameraStorage           : CameraStorage
    private let mapSettings             : MapSettings
    
    fileprivate let startZDistortionAffect      : Float
    fileprivate let endZDistortionAffect        : Float
    
    init(device: MTLDevice,
         mapZoomState: MapZoomState,
         cameraStorage: CameraStorage,
         frameCounter: FrameCounter,
         mapSettings: MapSettings) {
        
        self.maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        self.device = device
        self.mapZoomState = mapZoomState
        self.cameraStorage = cameraStorage
        self.frameCounter = frameCounter
        self.mapSettings = mapSettings
        self.maxLatitudeRadians = 2 * atan(exp(Float.pi)) - halfPi
        
        self.startZDistortionAffect = mapSettings.getMapCameraSettings().getCamAffectDistStartZ()
        self.endZDistortionAffect = mapSettings.getMapCameraSettings().getCamAffectDistEndZ()
        
        createUniformBuffers()
    }
    
    func getCurrentFrameBuffer() -> MTLBuffer {
        return uniformBuffers[currentBufferIndex]
    }
    
    func getCurrentFrameBufferIndex() -> Int {
        return currentBufferIndex
    }
    
    func updateUniforms(viewportSize: CGSize) {
        let camera              = cameraStorage.currentView
        currentBufferIndex      = (currentBufferIndex + 1) % maxBuffersInFlight
        let aspect              = Float(viewportSize.width / viewportSize.height)

        let nearAndFar          = camera.nearAndFar()
        let near                = nearAndFar.x
        let far                 = nearAndFar.y
        //print("near: \(near), far: \(far), camDist: \(camera.cameraDistance)")
        
        let currentZ = mapZoomState.zoomLevelFloat
        
        let range = endZDistortionAffect - startZDistortionAffect
        let distortionAffectValue: Float = max(0, min(1, (currentZ - startZDistortionAffect) / range))
        
        let mixValue = abs(camera.latitude / maxLatitudeRadians)  // от 0 (экватор) до 1 (полюс)
        let adjustedMix = pow(mixValue, 100.0) * distortionAffectValue  // нелинейная корректировка: медленнее в начале, быстрее в конце

        let baseFov = mapSettings.getMapCameraSettings().getBaseFov()
        let poleFov = mapSettings.getMapCameraSettings().getPoleFov()
        let fov = (1 - adjustedMix) * baseFov + adjustedMix * poleFov
        //print("fov = ", fov)
        
        // Create perspective projection matrix
        let projectionMatrix    = MatrixUtils.perspectiveMatrix(fovRadians: fov,
                                                                aspect: aspect,
                                                                near: max(0.0001, near),
                                                                far: far)
        
        // Create view matrix using look-at
        let postion             = camera.cameraPosition
        let target              = camera.targetPosition
        let up                  = camera.cameraQuaternion.act(SIMD3<Float>(0, 1, 0)) // Rotate up vector
        let viewMatrix          = MatrixUtils.lookAt(eye: postion,
                                                     center: target,
                                                     up: up)
        
        lastViewportSize        = SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height))
        
        // Update uniforms
        lastUniforms            = Uniforms(projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix,
                                           viewportSize: SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height)),
                                           elapsedTimeSeconds: frameCounter.getElapsedTimeSeconds())
        
        let buffer = uniformBuffers[currentBufferIndex]
        memcpy(buffer.contents(), &lastUniforms, MemoryLayout<Uniforms>.size)
    }
    
    private func createUniformBuffers() {
        let totalSize = MemoryLayout<Uniforms>.stride
        
        // Create multiple uniform buffers for triple buffering
        for _ in 0..<maxBuffersInFlight {
            let buffer = device.makeBuffer(length: totalSize, options: .storageModeShared)!
            uniformBuffers.append(buffer)
        }
    }
}
