//
//  Settings.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

class Settings {
    static let panSensitivity: Float = 2.6
    static let rotationSensitivity: Float = 0.2
    static let twoFingerPanSensitivity: Float = 0.003
    static let pinchSensitivity: Float = 1300
    
    static let farPlaneIncreaseFactor: Float = 2.0
    static let planesNearDelta: Float = -4.0
    static let planesFarDelta: Float = 2.0
    static let maxCameraPitch: Float = Float.pi / 2.2
    static let minCameraPitch: Float = 0
    
    static let mapSize: Float = 1000.0
    static let nullZoomCameraDistance: Float = 2200
    static let visibleTilesX: Int = 3
    static let visibleTilesY: Int = 3
    static let gridThickness: Float = 20
    static let cameraCenterPointSize: Float = 40
    static let axisLength: Float = Float.greatestFiniteMagnitude
    static let axisThickness: Float = 7
    static let clearDownloadedOnDiskTiles: Bool = false
    static let tileExtent = 4096
    
    static let spaceUnicodeNumber: Int = 32
    static let spaceSize: Float = 0.2
    
    // tile titles
    static let tileTitleRootSize: Float = 100.0
    static let tileTitleOffset: Float = 20.0
}
