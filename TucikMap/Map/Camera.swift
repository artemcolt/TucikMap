//
//  Camera.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import SwiftUI
import MetalKit

class Camera {
    let mapZoomState: MapZoomState
    
    // Camera properties
    private(set) var cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private(set) var targetPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // Точка, вокруг которой вращается камера
    private(set) var cameraDistance: Float = Settings.nullZoomCameraDistance // Расстояние от камеры до цели
    private(set) var cameraQuaternion: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1) // Кватернион ориентации камеры
    private(set) var cameraYawQuaternion: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1)
    private(set) var updateBufferedUnifrom: UpdateBufferedUniform? = nil
    private(set) var assembledMapUpdater: AssembledMapUpdater? = nil
    private(set) var forward: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    
    private(set) var cameraPitch: Float = 0
    private(set) var centerTileX: Float = 0
    private(set) var centerTileY: Float = 0
    
    private var previousCenterTileX: Int = -1
    private var previousCenterTileY: Int = -1
    
    init(mapZoomState: MapZoomState, device: MTLDevice, textTools: TextTools) {
        self.mapZoomState = mapZoomState
        self.updateBufferedUnifrom = UpdateBufferedUniform(device: device, mapZoomState: mapZoomState, camera: self)
        self.assembledMapUpdater = AssembledMapUpdater(mapZoomState: mapZoomState, device: device, camera: self, textTools: textTools)
    }
    
    // Handle single-finger pan gesture for target translation
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.panSensitivity * mapZoomState.mapScaleFactor
        
        let deltaX = -Float(translation.x) * sensitivity
        let deltaY = Float(translation.y) * sensitivity
        
        // Move target position in camera's local
        let right = cameraYawQuaternion.act(SIMD3<Float>(1, 0, 0))
        let forward = cameraYawQuaternion.act(SIMD3<Float>(0, 1, 0))
        targetPosition += right * deltaX + forward * deltaY
        
        gesture.setTranslation(.zero, in: view)
        
        movement(view: view, size: view.drawableSize)
    }
    
    // Handle two-finger rotation gesture for yaw
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let rotation = Float(gesture.rotation)
        let sensitivity: Float = Settings.rotationSensitivity
        let deltaYaw = -rotation * sensitivity // Negative for intuitive control
        
        // Rotate around world Z-axis (yaw)
        let yawQuaternion = simd_quatf(angle: deltaYaw, axis: SIMD3<Float>(0, 0, 1))
        cameraQuaternion = yawQuaternion * cameraQuaternion // for camera
        cameraYawQuaternion = yawQuaternion * cameraYawQuaternion // for panning
        
        gesture.rotation = 0
        
        movement(view: view, size: view.drawableSize)
    }
    
    // Handle two-finger pan gesture for pitch and zoom
    @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.twoFingerPanSensitivity
        let deltaPitch = -Float(translation.y) * sensitivity
        let newCameraPitch = max(min(cameraPitch + deltaPitch, Settings.maxCameraPitch), Settings.minCameraPitch)
        let quaternionDelta = newCameraPitch - cameraPitch
        
        // Rotate around local X-axis (pitch)
        if abs(quaternionDelta) > 0 {
            let right = cameraQuaternion.act(SIMD3<Float>(1, 0, 0))
            let pitchQuaternion = simd_quatf(angle: quaternionDelta, axis: right)
            cameraQuaternion = pitchQuaternion * cameraQuaternion
            cameraPitch = newCameraPitch
        }
        
        gesture.setTranslation(.zero, in: view)
        
        movement(view: view, size: view.drawableSize)
    }
    
    // Handle pinch gesture for camera distance (zoom)
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let scale = Float(gesture.scale)
        let sensitivity: Float = Settings.pinchSensitivity * mapZoomState.mapScaleFactor
        let deltaDistance = (1.0 - scale) * sensitivity // Negative for intuitive zoom: pinch in to zoom out, pinch out to zoom in
        
        // Adjust camera distance, with optional clamping to prevent extreme values
        cameraDistance += deltaDistance
        
        gesture.scale = 1.0 // Reset scale for next event
        
        movement(view: view, size: view.drawableSize)
    }
    
    func updateMap(view: MTKView, size: CGSize) {
        mapZoomState.update(cameraDistance: cameraDistance)
        
        // Compute camera position based on distance and orientation
        forward = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition = targetPosition + forward * cameraDistance
        
        updateBufferedUnifrom?.updateUniforms(viewportSize: size)
        view.setNeedsDisplay() // movement redraw
        
        let changed = updateCameraCenterTile()
        // reassemble map if needed
        // if there are new visible tiles
        if changed {
            assembledMapUpdater?.update(view: view)
        }
    }
    
    private func movement(view: MTKView, size: CGSize) {
        updateMap(view: view, size: size)
    }
    
    private func updateCameraCenterTile() -> Bool {
        let tileSize = mapZoomState.tileSize
        let mapSize = Settings.mapSize
        let worldTilesHalf = Float(mapZoomState.tilesCount) / 2.0 * tileSize
        
        // Определяем центр карты в координатах тайлов
        centerTileX = (targetPosition.x + worldTilesHalf) / tileSize
        centerTileY = (mapSize - (targetPosition.y + worldTilesHalf)) / tileSize
        
        let changed = Int(centerTileX) != previousCenterTileX || Int(centerTileY) != previousCenterTileY
        previousCenterTileX = Int(centerTileX)
        previousCenterTileY = Int(centerTileY)
        return changed
    }
}
