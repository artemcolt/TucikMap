//
//  Camera.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit

class Camera {
    var cameraContext       : CameraContext
    
    var mapSize : Float { get { return 0 } }
    var mapZoom : Float {
        get { return cameraContext.mapZoom }
        set { cameraContext.mapZoom = newValue }
    }
    var cameraYawQuaternion : simd_quatf {
        get { return cameraContext.cameraYawQuaternion }
        set { cameraContext.cameraYawQuaternion = newValue }
    }
    var cameraDistance : Float {
        get { return cameraContext.cameraDistance }
        set { cameraContext.cameraDistance = newValue }
    }
    var cameraPitch : Float {
        get { return cameraContext.cameraPitch }
        set { cameraContext.cameraPitch = newValue }
    }
    var cameraPosition : SIMD3<Float> {
        get { return cameraContext.cameraPosition }
        set { cameraContext.cameraPosition = newValue }
    }
    var targetPosition : SIMD3<Float> {
        get { return cameraContext.targetPosition }
        set { cameraContext.targetPosition = newValue }
    }
    var cameraQuaternion : simd_quatf {
        get { return cameraContext.cameraQuaternion }
        set { cameraContext.cameraQuaternion = newValue }
    }
    var rotationYaw : Float {
        get { return cameraContext.rotationYaw }
        set { cameraContext.rotationYaw = newValue }
    }
    
    var globeRadius                 : Float = 0
    var latitude                    : Float = 0
    var longitude                   : Float = 0
    var mapPanning                  : SIMD3<Double> = SIMD3<Double>(0, 0, 0) // смещение карты
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
         cameraContext: CameraContext) {
        
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
        //switchMapMode.switchModeFlag = true
    }
    
    func updateMap(view: MTKView, size: CGSize) {
        mapZoom = max(0, min(mapZoom, Settings.zoomLevelMax))
        cameraDistance = Settings.nullZoomCameraDistance / pow(2.0, mapZoom.truncatingRemainder(dividingBy: 1))
        mapZoomState.update(zoomLevelFloat: mapZoom, mapSize: mapSize)
        
        // Compute camera position based on distance and orientation
        let forward = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition = targetPosition + forward * cameraDistance
        
        // Зацикливаем карту
        let halfMapSize = Double(mapSize) / 2.0
        if mapPanning.x > halfMapSize {
            mapPanning.x = -halfMapSize
        } else if mapPanning.x < -halfMapSize {
            mapPanning.x = halfMapSize
        }
        mapPanning.y = max(-halfMapSize, min(halfMapSize, mapPanning.y))
        
        let mapSize     = Double(mapSize) // размер карты снизу и доверху
        let panY        = mapPanning.y // 0 в центре карты, на половине пути
        let mercY       = -panY / mapSize * 2.0 * Double.pi
        latitude        = Float(2.0 * atan(exp(mercY)) - Double.pi / 2)
        let panX        = mapPanning.x
        longitude       = -Float(panX / (mapSize / 2.0)) * Float.pi
        
        globeRadius     = Settings.nullZoomGlobeRadius * mapZoomState.powZoomLevel
        
        let _ = updateCameraCenterTile()
        
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
        
        if Settings.printCenterLatLon {
            print(getCenterLatLon())
        }
        
        // Так как камера перемещается нужно пересчитать метки на экране
        mapCadDisplayLoop.forceUpdateStates()
    }
    
    func applyMovementToCamera(view: MTKView) {
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
            
        updateMap(view: view, size: view.drawableSize)
    }
    
    func getCenterLatLon() -> (lat: Double, lon: Double) {
        let mapSize = Double(mapSize)
        
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
        let mapSize = Double(mapSize)
        
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
        let worldHalf = Float(mapZoomState.tilesCount) / 2.0 * tileSize
        
        // Определяем центр карты в координатах тайлов
        centerTileX = (-Float(mapPanning.x) + worldHalf) / tileSize
        centerTileY = (Float(mapPanning.y) + worldHalf) / tileSize
        
        let halfMapSize = Double(mapSize) / 2.0
        if mapPanning.x == halfMapSize {
            centerTileX = Float(mapZoomState.maxTileCoord)
        } else if mapPanning.x == -halfMapSize {
            centerTileX = Float(0)
        }
        
        let changed = Int(centerTileX) != previousCenterTileX || Int(centerTileY) != previousCenterTileY
                                                              || borderedZoomLevel != previousBorderedZoomLevel
        previousCenterTileX = Int(centerTileX)
        previousCenterTileY = Int(centerTileY)
        previousBorderedZoomLevel = borderedZoomLevel
        return changed
    }
}
