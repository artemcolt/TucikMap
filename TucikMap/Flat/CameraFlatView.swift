//
//  CameraFlatView.swift
//  TucikMap
//
//  Created by Artem on 7/24/25.
//

import MetalKit
import SwiftUI

class CameraFlatView : Camera {
    private(set) var centerTileX            : Float = 0
    private(set) var centerTileY            : Float = 0
    
    private var previousCenterTileX         : Int = -1
    private var previousCenterTileY         : Int = -1
    private var previousBorderedZoomLevel   : Int = -1
    private var mapStateUpdatedOnCenter     : SIMD2<Int> = SIMD2(-1, -1)
    
    
    override func nearAndFar() -> SIMD2<Float> {
        let halfPi              = Float.pi / 2
        let pitchAngle: Float   = cameraPitch
        let pitchNormalized     = pitchAngle / halfPi
        let nearFactor          = sqrt(pitchNormalized)
        let farFactor           = pitchAngle * Settings.farPlaneIncreaseFactor
        
        let delta: Float        = 1.0
        let near: Float         = cameraDistance - delta - nearFactor * cameraDistance
        var far: Float          = cameraDistance + delta + farFactor  * cameraDistance
        far += 5
        
        return SIMD2<Float>(near, far)
    }
    
    override func updateMap(view: MTKView, size: CGSize) {
        mapZoom = max(0, min(mapZoom, Settings.zoomLevelMax))
        cameraDistance = Settings.nullZoomCameraDistance / pow(2.0, mapZoom.truncatingRemainder(dividingBy: 1))
        mapZoomState.update(zoomLevelFloat: mapZoom)
        
        // Вернуть в допустимую зону камеру
        let zoomFactor = Double(pow(2.0, floor(mapZoom)))
        let visibleHeight = 2.0 * Double(cameraDistance) * Double(tan(Settings.fov / 2.0)) / zoomFactor
        let targetPositionYMin = Double(-Settings.mapSize) / 2.0 + visibleHeight / 2.0
        let targetPositionYMax = Double(Settings.mapSize) / 2.0  - visibleHeight / 2.0
//        if (mapPanning.y < targetPositionYMin) {
//            mapPanning.y = targetPositionYMin
//        } else if (mapPanning.y > targetPositionYMax) {
//            mapPanning.y = targetPositionYMax
//        }
        
        // Compute camera position based on distance and orientation
        forward = cameraQuaternion.act(SIMD3<Float>(0, 0, 1)) // Default forward vector
        cameraPosition = targetPosition + forward * cameraDistance
        
        let _ = updateCameraCenterTile()
        
        drawingFrameRequester.renderNextNFrames(Settings.maxBuffersInFlight)
        
        if Settings.printCenterLatLon {
            print(getCenterLatLon())
        }
        
        // Так как камера перемещается нужно пересчитать метки на экране
        mapCadDisplayLoop.forceUpdateStates()
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
        if mapStateUpdatedOnCenter != SIMD2<Int>(Int(centerTileX), Int(centerTileY)) {
            mapStateUpdatedOnCenter = SIMD2<Int>(Int(centerTileX), Int(centerTileY))
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
        
        //print("centerTileX \(centerTileX) centerTileY \(centerTileY)")
        
        let changed = Int(centerTileX) != previousCenterTileX || Int(centerTileY) != previousCenterTileY
                                                              || borderedZoomLevel != previousBorderedZoomLevel
        previousCenterTileX = Int(centerTileX)
        previousCenterTileY = Int(centerTileY)
        previousBorderedZoomLevel = borderedZoomLevel
        return changed
    }
}
