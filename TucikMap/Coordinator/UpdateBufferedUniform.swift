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
    
    private(set) var currentBufferIndex = -1
    private(set) var semaphore: DispatchSemaphore!
    
    private let maxBuffersInFlight = 3
    private let device: MTLDevice
    private let mapZoomState: MapZoomState
    private let camera: Camera
    private let halfPi = Float.pi / 2
    
    init(device: MTLDevice, mapZoomState: MapZoomState, camera: Camera) {
        // Initialize semaphore for triple buffering
        self.semaphore = DispatchSemaphore(value: 3)
        self.device = device
        self.mapZoomState = mapZoomState
        self.camera = camera
        createUniformBuffers()
    }
    
    func getCurrentFrameBuffer() -> MTLBuffer {
        return uniformBuffers[currentBufferIndex]
    }
    
    func updateUniforms(viewportSize: CGSize) {
        currentBufferIndex = (currentBufferIndex + 1) % maxBuffersInFlight
        let aspect = Float(viewportSize.width / viewportSize.height)
        
        let pitchAngle: Float = camera.cameraPitch
        let pitchNormalized = pitchAngle / halfPi
        let nearFactor = sqrt(pitchNormalized)
        let farFactor = pitchAngle * Settings.farPlaneIncreaseFactor

        let near: Float = camera.cameraDistance + Settings.planesNearDelta * mapZoomState.mapScaleFactor - nearFactor * camera.cameraDistance
        let far: Float = camera.cameraDistance + Settings.planesFarDelta  * mapZoomState.mapScaleFactor + farFactor  * camera.cameraDistance
        //print("near: \(near), far: \(far), camDist: \(camera.cameraDistance)")
        
        // Create perspective projection matrix
        let projectionMatrix = MatrixUtils.perspectiveMatrix(
            fovRadians: Float.pi / 3.0,
            aspect: aspect,
            near: max(near, 0.0001),
            far: far
        )
        
        
        // Create view matrix using look-at
        let up = camera.cameraQuaternion.act(SIMD3<Float>(0, 1, 0)) // Rotate up vector
        let viewMatrix = MatrixUtils.lookAt(
            eye: camera.cameraPosition,
            center: camera.targetPosition,
            up: up
        )
        
        // Update uniforms
        var uniforms = Uniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
        )
        
        let buffer = uniformBuffers[currentBufferIndex]
        memcpy(buffer.contents(), &uniforms, MemoryLayout<Uniforms>.size)
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
