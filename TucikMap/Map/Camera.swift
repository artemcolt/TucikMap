//
//  Camera.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit

class Camera {
    var cameraContext       : CameraContext
    var mapModeStorage      : MapModeStorage
    var mapPanning          : SIMD3<Double> {
        get { return cameraContext.mapPanning }
        set { cameraContext.mapPanning = newValue }
    }
    
    var mapZoom                     : Float = 0
    var cameraYawQuaternion         : simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1)
    var forward                     : SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    
    var cameraDistance              : Float = 0
    var cameraPitch                 : Float = 0
    var cameraPosition              : SIMD3<Float> = SIMD3<Float>()
    var targetPosition              : SIMD3<Float> = SIMD3<Float>()
    var cameraQuaternion            : simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1)
    var rotationYaw                 : Float = 0
    
    var pinchDeltaDistance          : Float = 0
    var twoFingerDeltaPitch         : Float = 0
    var panDeltaX                   : Float = 0
    var panDeltaY                   : Float = 0
    var rotationDeltaYaw            : Float = 0
    
    let mapZoomState                : MapZoomState
    let drawingFrameRequester       : DrawingFrameRequester
    let mapCadDisplayLoop           : MapCADisplayLoop

    init(mapZoomState: MapZoomState,
         drawingFrameRequester: DrawingFrameRequester,
         mapCadDisplayLoop: MapCADisplayLoop,
         cameraContext: CameraContext,
         mapModeStorage: MapModeStorage) {
        
        self.mapModeStorage = mapModeStorage
        self.mapZoomState = mapZoomState
        self.drawingFrameRequester = drawingFrameRequester
        self.mapCadDisplayLoop = mapCadDisplayLoop
        self.cameraContext = cameraContext
    }
    
    func nearAndFar() -> SIMD2<Float> {
        return SIMD2<Float>(0, 0)
    }
    
    // Handle single-finger pan gesture for target translation
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.panSensitivity / pow(2.0, mapZoom)
        
        panDeltaX = Float(translation.x) * sensitivity
        panDeltaY = -Float(translation.y) * sensitivity
        gesture.setTranslation(.zero, in: view)
        
        applyMovementToCamera(view: view)
    }
    
    // Handle two-finger rotation gesture for yaw
    func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let rotation = Float(gesture.rotation)
        let sensitivity: Float = Settings.rotationSensitivity
        rotationDeltaYaw = -rotation * sensitivity // Negative for intuitive control
        gesture.rotation = 0
        
        applyMovementToCamera(view: view)
    }
    
    // Handle two-finger pan gesture for pitch and zoom
    func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let translation = gesture.translation(in: view)
        let sensitivity: Float = Settings.twoFingerPanSensitivity
        twoFingerDeltaPitch = -Float(translation.y) * sensitivity
        gesture.setTranslation(.zero, in: view)
        
        applyMovementToCamera(view: view)
    }
    
    // Handle pinch gesture for camera distance (zoom)
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        
        let scale = Float(gesture.scale)
        let sensitivity: Float = Settings.pinchSensitivity * abs(Float(gesture.velocity))
        pinchDeltaDistance = (1.0 - scale) * sensitivity // Negative for intuitive zoom: pinch in to zoom out, pinch out to zoom in
        gesture.scale = 1.0 // Reset scale for next event
        
        applyMovementToCamera(view: view)
    }
    
    func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? MTKView else { return }
        mapModeStorage.switchState()
    }
    
    func updateMap(view: MTKView, size: CGSize) { }
    
    private func applyMovementToCamera(view: MTKView) {
        // pinch
        // Adjust camera distance, with optional clamping to prevent extreme values
        mapZoom -= pinchDeltaDistance
        
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
        rotationYaw += rotationDeltaYaw
        let yawQuaternion = simd_quatf(angle: rotationDeltaYaw, axis: SIMD3<Float>(0, 0, 1))
        cameraQuaternion = yawQuaternion * cameraQuaternion // for camera
        cameraYawQuaternion = yawQuaternion * cameraYawQuaternion // for panning
        
        // Pan
        // Move target position in camera's local
        let right = cameraYawQuaternion.act(SIMD3<Float>(1, 0, 0))
        let forward = cameraYawQuaternion.act(SIMD3<Float>(0, 1, 0))
        let newMapPanning = mapPanning + SIMD3<Double>(right * panDeltaX + forward * panDeltaY)
        mapPanning.y = newMapPanning.y
        mapPanning.x = newMapPanning.x
        
        print(mapPanning)
            
        updateMap(view: view, size: view.drawableSize)
    }
}
