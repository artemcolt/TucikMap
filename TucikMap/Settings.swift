//
//  Settings.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import GISTools
import Foundation
import simd

class Settings {
    static var forceRenderOnDisplayUpdate   : Bool = false
    
    
    static let visibleTilesBorder: Int = 3
    static let visibleTilesCount: Int = visibleTilesBorder * visibleTilesBorder
    
    
    
    static let maxBuffersInFlight: Int = 3
    
    static let rotationSensitivity: Float = 0.2
    static let twoFingerPanSensitivity: Float = 0.003
    static let panSensitivity: Float = 0.001
    static let pinchSensitivity: Float = 0.1
    static let maxCameraPitch: Float = Float.pi / 3
    static let minCameraPitch: Float = 0
    static let fov: Float = Float.pi / 3.0
    
    
    
    
    static let nullZoomCameraDistance: Float = 1.0 / (2 * tan(fov / 2))
    static let minCameraDistance: Float = nullZoomCameraDistance / pow(2, 18)
    static let farPlaneIncreaseFactor: Float = 2.0
    static let nullZoomGlobeRadius: Float = 0.2
    
    static let globeMapSize: Float = 1.0
    static let baseFlatMapSize: Float = 2 * Float.pi * nullZoomGlobeRadius
    
    static let maxTileZoom: Int = 16
    
    static let gridThickness: Float = 20
    static let cameraCenterPointSize: Float = 0.01
    static let axisLength: Float = 10_000
    static let axisThickness: Float = 20
    static let tileExtent = 4096
    
    static let clearDownloadedOnDiskTiles: Bool = false

    static let spaceUnicodeNumber: Int = 32
    static let spaceSize: Float = 0.2
    
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
    
    
    static var maxInputComputeScreenPoints  : Int = 3000
    
    static var labelsFadeAnimationTimeSeconds: Float = 0.3 // 0.3
    static let buildingsFactor = 0.006
    
    static let zoomLevelMax             : Float = 20.9
    
    static let printCenterLatLon        : Bool = false
    static let printCenterTile          : Bool = false
    static let showOnlyTiles            : [Tile] = []
    static let allowOnlyTiles           : [Tile] = []
    
    static let maxRoadLabelsDivision = 1
    static let roadLabelScreenSpacing = Float(0)
    
    static let getOnlySpecificMapLabels: [String] = [] // "Cameroon", "Nigeria", "South Sudan", "Africa", "South Sudan", "Kitay-gorod"
    static let renderOnlyRoadsArray: [String] = [] // "Sofiyskaya Embankment" "Kremlin Embankment" "Ilyinka St" "Raushskaya Embankment" "Ilyinka St"
    static let renderRoadArrayFromTo: [Int] = [] // 0, 0
    
    static let drawRoadPointsDebug: Bool = false
    
    static let roadLabelTextSize: Float = 50
    static let geoLabelsParametersBufferSize: Int = 40
    
    static let printRoadLabelsCount: Bool = false
    static let filterRoadLenLabel: Float = 0.3
    static let printVisibleTiles: Bool = false
    static let printVisibleAreaRange: Bool = false
    
    
    static let globeTextureSize: Int = 4096 * 2
    
    static let globeToPlaneZoomStart: Float = 4
    static let globeToPlaneZoomEnd: Float = 5
    
    static let tileBgColor: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
    static let backgroundColor: SIMD4<Double> = SIMD4<Double>(0.0039, 0.0431, 0.0980, 1.0) // Тёмно-синий "deep space" для атмосферы космоса
    static let waterColor: SIMD4<Float> = SIMD4<Float>(0.3, 0.6, 0.9, 1.0) // Light blue
    static let landCoverColor: SIMD4<Float> = SIMD4<Float>(0.4, 0.7, 0.4, 0.7)  // Grass green
    
    static let northPoleColor: SIMD4<Float> = waterColor
    static let southPoleColor: SIMD4<Float> = blend(source: landCoverColor, destination: tileBgColor)
    
    static func blend(source: SIMD4<Float>, destination: SIMD4<Float>) -> SIMD4<Float> {
        let sourceAlpha = source.w
        let oneMinusSourceAlpha = 1 - sourceAlpha
        
        let sourceXYZ = SIMD3<Float>(source.x, source.y, source.z)
        let destinationXYZ = SIMD3<Float>(destination.x, destination.y, destination.z)
        
        // Blended RGB: (source.rgb * sourceAlpha) + (destination.rgb * oneMinusSourceAlpha)
        let blendedRGB = (sourceXYZ * sourceAlpha) + (destinationXYZ * oneMinusSourceAlpha)

        // Blended Alpha: (sourceAlpha * sourceAlpha) + (destination.w * oneMinusSourceAlpha)
        let blendedAlpha = (sourceAlpha * sourceAlpha) + (destination.w * oneMinusSourceAlpha)

        let resultingColor = SIMD4<Float>(blendedRGB.x, blendedRGB.y, blendedRGB.z, blendedAlpha)
        return resultingColor
    }
}
