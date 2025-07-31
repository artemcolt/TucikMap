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
    
    var mapPanning : SIMD3<Double> {
        get { return cameraContext.mapPanning }
        set { cameraContext.mapPanning = newValue }
    }
    var mapZoom : Float {
        get { return cameraContext.mapZoom }
        set { cameraContext.mapZoom = newValue }
    }
    
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
    
    var previousBorderedZoomLevel   : Int = -1
    var centerTileX                 : Float = 0
    var centerTileY                 : Float = 0
    var previousCenterTileX         : Int = -1
    var previousCenterTileY         : Int = -1
    var mapStateUpdatedOnCenter     : SIMD3<Int> = SIMD3(-1, -1, -1)
    
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
        mapModeStorage.switchState()
    }
    
    func updateMap(view: MTKView, size: CGSize) {
        let _ = updateCameraCenterTile()
        
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
        
        if Settings.printCenterLatLon {
            print(getCenterLatLon())
        }
        
        // Так как камера перемещается нужно пересчитать метки на экране
        mapCadDisplayLoop.forceUpdateStates()
    }
    
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
        
        //print(mapPanning)
            
        updateMap(view: view, size: view.drawableSize)
    }
    
    func getCenterLatLon() -> (lat: Double, lon: Double) {
        let mapSize = Double(Settings.mapSize)
        
        // Step 1: Reverse the map offset to get Mercator coordinates x and y
        let x = mapSize / 2 - mapPanning.x
        let y = mapSize / 2 - mapPanning.y
        
        // Step 2: Convert Mercator x to longitude
        let lon = (x / mapSize * 360.0) - 180.0
        
        // Step 3: Convert Mercator y to latitude
        let latRad = 2.0 * (atan(exp(.pi * (1.0 - 2.0 * y / mapSize))) - .pi / 4)
        let lat = -latRad * 180.0 / .pi
        
        return (lat: lat, lon: lon)
    }
    
    func moveTo(lat: Double, lon: Double, zoom: Float, view: MTKView, size: CGSize) {
        mapZoom = zoom
        
        let lat = -lat
        let mapSize = Double(Settings.mapSize)
        
        // Шаг 1: Преобразование lat, lon в координаты Меркатора
        let _ = lon * .pi / 180
        let latRad = lat * .pi / 180
        
        let x = (lon + 180) / 360 * mapSize
        let y = (1 - log(tan(.pi / 4 + latRad / 2)) / .pi) / 2 * mapSize
        
        // Шаг 3: Расчет смещения карты
        let newX = mapSize / 2 - x
        let newY = mapSize / 2 - y
        mapPanning = SIMD3<Double>(newX, newY, 0)
        
        // Шаг 4: Обновление карты
        updateMap(view: view, size: size)
    }
    
    func moveToPanningPoint(point: MapPanningTilePoint, zoom: Float, view: MTKView, size: CGSize) {
        self.mapZoom = zoom
        mapPanning = SIMD3<Double>(point.x, point.y, 0)
        updateMap(view: view, size: size)
    }
    
    func isMapStateUpdated() -> Bool {
        if mapStateUpdatedOnCenter != SIMD3<Int>(Int(centerTileX), Int(centerTileY), Int(mapZoomState.zoomLevel)) {
            mapStateUpdatedOnCenter = SIMD3<Int>(Int(centerTileX), Int(centerTileY), Int(mapZoomState.zoomLevel))
            return true
        }
        return false
    }
    
    private func updateCameraCenterTile() -> Bool {
        let tileSize = mapZoomState.tileSize
        let borderedZoomLevel = mapZoomState.zoomLevel
        let worldTilesHalf = Float(mapZoomState.tilesCount) / 2.0 * tileSize
        
        // Определяем центр карты в координатах тайлов
        centerTileX = (-Float(mapPanning.x) + worldTilesHalf) / tileSize
        centerTileY = (Float(mapPanning.y) + worldTilesHalf) / tileSize
        
        let changed = Int(centerTileX) != previousCenterTileX || Int(centerTileY) != previousCenterTileY
                                                              || borderedZoomLevel != previousBorderedZoomLevel
        previousCenterTileX = Int(centerTileX)
        previousCenterTileY = Int(centerTileY)
        previousBorderedZoomLevel = borderedZoomLevel
        return changed
    }
}
