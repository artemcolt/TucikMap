//
//  UpdateBufferedUniform.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import SwiftUI
import MetalKit


class UpdateBufferedUniform {
    // Triple buffering for uniforms
    private(set) var uniformBuffers: [MTLBuffer] = []
    
    private var currentBufferIndex = -1
    private(set) var semaphore: DispatchSemaphore!
    private(set) var lastUniforms: Uniforms?
    private(set) var lastViewportSize: SIMD2<Float>!
    
    private let frameCounter: FrameCounter
    private let maxBuffersInFlight = Settings.maxBuffersInFlight
    private let device: MTLDevice
    private let mapZoomState: MapZoomState
    private let camera: Camera
    private let halfPi = Float.pi / 2
    
    init(device: MTLDevice, mapZoomState: MapZoomState, camera: Camera, frameCounter: FrameCounter) {
        // Initialize semaphore for triple buffering
        self.semaphore = DispatchSemaphore(value: Settings.maxBuffersInFlight)
        self.device = device
        self.mapZoomState = mapZoomState
        self.camera = camera
        self.frameCounter = frameCounter
        createUniformBuffers()
    }
    
    func getCurrentFrameBuffer() -> MTLBuffer {
        return uniformBuffers[currentBufferIndex]
    }
    
    func getCurrentFrameBufferIndex() -> Int {
        return currentBufferIndex
    }
    
    func updateUniforms(viewportSize: CGSize) {
        currentBufferIndex = (currentBufferIndex + 1) % maxBuffersInFlight
        let aspect = Float(viewportSize.width / viewportSize.height)

        let pitchAngle: Float = camera.cameraPitch
        let pitchNormalized = pitchAngle / halfPi
        let nearFactor = sqrt(pitchNormalized)
        let farFactor = pitchAngle * Settings.farPlaneIncreaseFactor

        let delta: Float = 1.0
        let near: Float = camera.cameraDistance - delta - nearFactor * camera.cameraDistance
        var far: Float = camera.cameraDistance + delta + farFactor  * camera.cameraDistance
        far += 5
        //print("near: \(near), far: \(far), camDist: \(camera.cameraDistance)")
        
        // Create perspective projection matrix
        let projectionMatrix = MatrixUtils.perspectiveMatrix(
            fovRadians: Float.pi / 3.0,
            aspect: aspect,
            near: max(0.05, near),
            far: far
        )
        
        // Create view matrix using look-at
        let up = camera.cameraQuaternion.act(SIMD3<Float>(0, 1, 0)) // Rotate up vector
        let viewMatrix = MatrixUtils.lookAt(
            eye: camera.cameraPosition,
            center: camera.targetPosition,
            up: up
        )
        
        lastViewportSize = SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height))
        
        // Update uniforms
        lastUniforms = Uniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            viewportSize: SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height)),
            elapsedTimeSeconds: frameCounter.getElapsedTimeSeconds()
        )
        
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
