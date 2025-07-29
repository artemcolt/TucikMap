//
//  Settings.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import GISTools
import Foundation

class Settings {
    static let maxBuffersInFlight: Int = 3
    
    static let rotationSensitivity: Float = 0.2
    static let twoFingerPanSensitivity: Float = 0.003
    static let panSensitivity: Float = 0.001
    static let pinchSensitivity: Float = 0.1
    static let maxCameraPitch: Float = Float.pi / 3
    static let minCameraPitch: Float = 0
    static let fov: Float = Float.pi / 3.0
    static let mapSize: Float = 1.0
    static let nullZoomCameraDistance: Float = mapSize / (2 * tan(fov / 2))
    static let minCameraDistance: Float = nullZoomCameraDistance / pow(2, 18)
    static let farPlaneIncreaseFactor: Float = 2.0
    static let nullZoomGlobeRadius: Float = 0.2
    
    static let maxTileZoom: Int = 16
    static let visibleTilesCount: Int = 9
    static let visibleTilesX: Int = 3
    static let visibleTilesY: Int = 3
    
    static let gridThickness: Float = 20
    static let cameraCenterPointSize: Float = 0.01
    static let axisLength: Float = 10_000
    static let axisThickness: Float = 20
    static let tileExtent = 4096
    
    static let clearDownloadedOnDiskTiles: Bool = false

    static let spaceUnicodeNumber: Int = 32
    static let spaceSize: Float = 0.2
    
    // tile titles
    static let tileTitleRootSize: Float = 100.0
    static let tileTitleOffset: Float = 20.0
    
    static var drawAxis: Bool = false
    static var drawGrid: Bool = false
    static var drawTileCoordinates: Bool = false
    
    static var printNotUsedStyle: Bool = false
    static var filterNotUsedLayernName: String = "road"
    
    static var debugAssemblingMap: Bool = false
    static var debugIntersectionsLabels: Bool = false
    
    static let maxConcurrentFetchs = 3
    static let fetchTilesQueueCapacity = Settings.visibleTilesCount // can't be lesser than visible tiles count
    
    static let maxCachedTilesCount = 100
    static let maxCachedTilesMemory = 500 * 1024 * 1024
    
    static let enabledThrottling = false
    static let throttlingNanoSeconds: UInt64 = 4_000_000_000
    
    
    static let preferredFramesPerSecond = 60
    
    static let refreshLabelsIntersectionsEveryNDisplayLoop: UInt64 = 10
    
    static var forceRenderOnDisplayUpdate   : Bool = false
    
    static var horizontalGridDivisionSize   : Float = 500
    static var verticalGridDivisionSize     : Float = 500
    static var maxInputComputeScreenPoints  : Int = 3000
    
    static var labelsFadeAnimationTimeSeconds: Float = 0.3 // 0.3
    static let buildingsFactor = 0.006
    
    static let zoomLevelMax             : Float = 20.9
    
    static let gridCollisionSize        : Float = 1000
    static let worldCollisionSize       : Float = 12_000
    static let shiftCollisionLocation   : Float = 5_000
    
    static let printCenterLatLon        : Bool = false
    static let printCenterTile          : Bool = true
    static let showOnlyTiles            : [Tile] = [] // Tile(x: 39617, y: 20488, z: 16)
    static let allowOnlyTiles           : [Tile] = [] // Tile(x: 19808, y: 10244, z: 15) Tile(x: 19808, y: 10244, z: 15), Tile(x: 39617, y: 20488, z: 16)
    
    static let useGoToAtStart = true
    static let goToAtStartZ: Float = 2.0
    static let goToLocationAtStart: SIMD2<Double> = SIMD2<Double>(0, 0) // 55.74958790780624, 37.62346867711091
    
    static let maxRoadLabelsDivision = 1
    static let roadLabelScreenSpacing = Float(0)
    
    static let getOnlySpecificMapLabels: [String] = [] // "Cameroon", "Nigeria", "South Sudan", "Africa", "South Sudan", "Kitay-gorod"
    static let renderOnlyRoadsArray: [String] = [] // "Sofiyskaya Embankment" "Kremlin Embankment" "Ilyinka St" "Raushskaya Embankment" "Ilyinka St"
    static let renderRoadArrayFromTo: [Int] = [] // 0, 0
    
    static let drawRoadPointsDebug: Bool = false
    
    static let roadLabelTextSize: Float = 50
    static let geoLabelsModelMatrixBufferSize: Int = 40
    
    static let printRoadLabelsCount: Bool = false
    static let filterRoadLenLabel: Float = 0.3
    static let printVisibleTiles: Bool = false
    static let printVisibleAreaRange: Bool = true
    
    static let addTestBorders = true
}
