//
//  MapState.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import simd

class MapZoomState {
    private let nullZoomCameraDistance = Settings.nullZoomCameraDistance
    private let baseTileSize: Float = Settings.mapSize
    
    private(set) var zoomLevelFloat: Float = 0
    private(set) var zoomLevel: Int = 0
    private(set) var mapScaleFactor: Float = 1.0
    private(set) var powZoomLevel: Float = 0
    private(set) var tileSize: Float = 0
    private(set) var maxTileCoord: Int = 0
    private(set) var tilesCount: Int = 0
    
    
    func update(cameraDistance: Float) {
        // Вычисляем уровень зума на основе расстояния камеры
        zoomLevelFloat = calculateZoomLevel(cameraDistance: cameraDistance)
        zoomLevel = Int(floor(zoomLevelFloat))
        mapScaleFactor = 1.0 / pow(2.0, Float(zoomLevelFloat))
        powZoomLevel = pow(2.0, Float(zoomLevel))
        tileSize = baseTileSize / powZoomLevel
        tilesCount = Int(powZoomLevel)
        maxTileCoord = tilesCount - 1
    }
    
    private func calculateZoomLevel(cameraDistance: Float) -> Float {
        // Если камера на расстоянии nullZoomCameraDistance, зум = 0
        // При уменьшении расстояния зум увеличивается
        if cameraDistance <= 0 {
            return 0
        }
        
        // Используем логарифмическую зависимость для расчета зума
        // Когда расстояние уменьшается вдвое, зум увеличивается на 1
        let zoom = log2(nullZoomCameraDistance / cameraDistance)
        return max(0, zoom) // Не допускаем отрицательный зум
    }
}
