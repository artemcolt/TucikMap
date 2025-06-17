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
    let renderFrameCount: RenderFrameCount
    
    // Camera properties
    private(set) var cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    let targetPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // Точка, вокруг которой вращается камера
    private(set) var mapPanning: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // смещение карты
    private(set) var cameraDistance: Float = Settings.nullZoomCameraDistance // Расстояние от камеры до цели
    private(set) var cameraQuaternion: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1) // Кватернион ориентации камеры
    private(set) var cameraYawQuaternion: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1)
    private(set) var updateBufferedUniform: UpdateBufferedUniform!
    private(set) var assembledMapUpdater: AssembledMapUpdater!
    private(set) var forward: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    
    private(set) var cameraPitch: Float = 0
    private(set) var centerTileX: Float = 0
    private(set) var centerTileY: Float = 0
    
    private var previousCenterTileX: Int = -1
    private var previousCenterTileY: Int = -1
    private var previousBorderedZoomLevel: Int = -1
    
    private var pinchDeltaDistance: Float = 0
    private var twoFingerDeltaPitch: Float = 0
    private var rotationDeltaYaw: Float = 0
    private var panDeltaX: Float = 0
    private var panDeltaY: Float = 0
    
    private var lastTime: TimeInterval = 0
    
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        textTools: TextTools,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        self.renderFrameCount = renderFrameCount
        self.mapZoomState = mapZoomState
        self.updateBufferedUniform = UpdateBufferedUniform(device: device, mapZoomState: mapZoomState, camera: self, frameCounter: frameCounter)
        self.assembledMapUpdater = AssembledMapUpdater(
            mapZoomState: mapZoomState,
            device: device,
            camera: self,
            textTools: textTools,
            renderFrameCount: renderFrameCount
        )
    }
    
    // Handle single-finger pan gesture for target translation
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.panSensitivity * mapZoomState.mapScaleFactor
        
        panDeltaX = Float(translation.x) * sensitivity
        panDeltaY = -Float(translation.y) * sensitivity
        gesture.setTranslation(.zero, in: view)
        
        applyMovementToCamera(view: view)
    }
    
    // Handle two-finger rotation gesture for yaw
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let rotation = Float(gesture.rotation)
        let sensitivity: Float = Settings.rotationSensitivity
        rotationDeltaYaw = -rotation * sensitivity // Negative for intuitive control
        gesture.rotation = 0
        
        applyMovementToCamera(view: view)
    }
    
    // Handle two-finger pan gesture for pitch and zoom
    @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.twoFingerPanSensitivity
        twoFingerDeltaPitch = -Float(translation.y) * sensitivity
        gesture.setTranslation(.zero, in: view)
        
        applyMovementToCamera(view: view)
    }
    
    // Handle pinch gesture for camera distance (zoom)
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let scale = Float(gesture.scale)
        let sensitivity: Float = Settings.pinchSensitivity * mapZoomState.mapScaleFactor * abs(Float(gesture.velocity))
        pinchDeltaDistance = (1.0 - scale) * sensitivity // Negative for intuitive zoom: pinch in to zoom out, pinch out to zoom in
        gesture.scale = 1.0 // Reset scale for next event
        
        applyMovementToCamera(view: view)
    }
    
    @objc func applyMovementToCamera(view: MTKView) {
        assembledMapUpdater.needComputeLabelsIntersections.setNeedsRecompute()
        
        // pinch
        // Adjust camera distance, with optional clamping to prevent extreme values
        cameraDistance += pinchDeltaDistance
        cameraDistance = max(min(Settings.nullZoomCameraDistance, cameraDistance), Settings.minCameraDistance)
        
        // two finger
        let newCameraPitch = max(min(cameraPitch + twoFingerDeltaPitch, Settings.maxCameraPitch), Settings.minCameraPitch)
        let quaternionDelta = newCameraPitch - cameraPitch
        // Rotate around local X-axis (pitch)
        if abs(quaternionDelta) > 0 {
            let right = cameraQuaternion.act(SIMD3<Float>(1, 0, 0))
            let pitchQuaternion = simd_quatf(angle: quaternionDelta, axis: right)
            cameraQuaternion = pitchQuaternion * cameraQuaternion
            cameraPitch = newCameraPitch
        }
        
        // Rotation
        // Rotate around world Z-axis (yaw)
        let yawQuaternion = simd_quatf(angle: rotationDeltaYaw, axis: SIMD3<Float>(0, 0, 1))
        cameraQuaternion = yawQuaternion * cameraQuaternion // for camera
        cameraYawQuaternion = yawQuaternion * cameraYawQuaternion // for panning
        
        let visibleHeight = 2 * cameraDistance * tan(Settings.fov / 2)
        let targetPositionYMin = -Settings.mapSize / 2 + visibleHeight / 2
        let targetPositionYMax = Settings.mapSize / 2 - visibleHeight / 2
        
        
        // Pan
        // Move target position in camera's local
        let right = cameraYawQuaternion.act(SIMD3<Float>(1, 0, 0))
        let forward = cameraYawQuaternion.act(SIMD3<Float>(0, 1, 0))
        let newMapPanning = mapPanning + right * panDeltaX + forward * panDeltaY
        if (newMapPanning.y >= targetPositionYMin && newMapPanning.y <= targetPositionYMax) {
            mapPanning.y = newMapPanning.y
        }
        mapPanning.x = newMapPanning.x
        
        // return to available range
        if (mapPanning.y < targetPositionYMin) {
            mapPanning.y = targetPositionYMin
        } else if (mapPanning.y > targetPositionYMax) {
            mapPanning.y = targetPositionYMax
        }
        
        updateMap(view: view, size: view.drawableSize)
    }
    
    func updateMap(view: MTKView, size: CGSize) {
        mapZoomState.update(cameraDistance: cameraDistance)
        
        // Compute camera position based on distance and orientation
        forward = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition = targetPosition + forward * cameraDistance
        
        let changed = updateCameraCenterTile()
        // reassemble map if needed
        // if there are new visible tiles
        if changed {
            assembledMapUpdater?.update(view: view, useOnlyCached: false)
        }
        
        renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight)
    }
    
    private func updateCameraCenterTile() -> Bool {
        let tileSize = mapZoomState.tileSize
        let borderedZoomLevel = mapZoomState.zoomLevel
        let worldTilesHalf = Float(mapZoomState.tilesCount) / 2.0 * tileSize
        
        // Определяем центр карты в координатах тайлов
        centerTileX = (-mapPanning.x + worldTilesHalf) / tileSize
        centerTileY = (mapPanning.y + worldTilesHalf) / tileSize
        
        //print("centerTileX \(centerTileX) centerTileY \(centerTileY)")
        
        let changed = Int(centerTileX) != previousCenterTileX || Int(centerTileY) != previousCenterTileY
                                                              || borderedZoomLevel != previousBorderedZoomLevel
        previousCenterTileX = Int(centerTileX)
        previousCenterTileY = Int(centerTileY)
        previousBorderedZoomLevel = borderedZoomLevel
        return changed
    }
    
    private func getDeltaTime() -> Float {
        let currentTime = CACurrentMediaTime()
        let deltaTime = lastTime == 0 ? 1.0 / 60.0 : min(currentTime - lastTime, 0.1) // Ограничение скачков
        lastTime = currentTime
        return Float(deltaTime)
    }
}
