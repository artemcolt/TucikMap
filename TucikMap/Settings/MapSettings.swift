//
//  MapSettings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import SwiftUI
import MetalKit

class MapSettings {
    fileprivate let mapCameraSettings: MapCameraSettings
    fileprivate let mapDebugSettings: MapDebugSettings
    fileprivate let mapCommonSettings: MapCommonSettings
    fileprivate let mapBaseColors: MapBaseColors
    
    public func getMapCameraSettings() -> MapCameraSettings {
        return mapCameraSettings
    }
    
    public func getMapDebugSettings() -> MapDebugSettings {
        return mapDebugSettings
    }
    
    public func getMapCommonSettings() -> MapCommonSettings {
        return mapCommonSettings
    }
    
    public func getMapBaseColors() -> MapBaseColors {
        return mapBaseColors
    }
    
    init(mapCameraSettings: MapCameraSettings = MapCameraSettings(),
         mapDebugSettings: MapDebugSettings = MapDebugSettings(),
         mapCommonSettings: MapCommonSettings = MapCommonSettings(),
         mapBaseColors: MapBaseColors = MapBaseColors()) {
        self.mapCameraSettings = mapCameraSettings
        self.mapDebugSettings = mapDebugSettings
        self.mapCommonSettings = mapCommonSettings
        self.mapBaseColors = mapBaseColors
    }
    
}

class MapSettingsBuilder {
    private var mapCameraSettings = MapCameraSettings()
    private var mapDebugSettings = MapDebugSettings()
    private var mapCommonSettings = MapCommonSettings()
    
    public func getMapCameraSettings() -> MapCameraSettings {
        return mapCameraSettings
    }
    
    func initPosition(z: Float, latLon: SIMD2<Double>) -> MapSettingsBuilder {
        mapCameraSettings.z = z
        mapCameraSettings.latLon = latLon
        return self
    }
    
    func debugUI(enabled: Bool) -> MapSettingsBuilder {
        mapDebugSettings.drawBaseDebug = enabled
        return self
    }
    
    func renderOnDisplayUpdate(enabled: Bool) -> MapSettingsBuilder {
        mapCommonSettings.forceRenderOnDisplayUpdate = enabled
        return self
    }
    
    func build() -> MapSettings {
        return MapSettings(mapCameraSettings: mapCameraSettings,
                           mapDebugSettings: mapDebugSettings,
                           mapCommonSettings: mapCommonSettings)
    }
}


class MapBaseColors {
    fileprivate let tileBgColor: SIMD4<Float>
    fileprivate let backgroundColor: SIMD4<Double>
    fileprivate let waterColor: SIMD4<Float>
    fileprivate let landCoverColor: SIMD4<Float>
    fileprivate let northPoleColor: SIMD4<Float>
    fileprivate let southPoleColor: SIMD4<Float>
    
    public func getTileBgColor() -> SIMD4<Float> {
        return tileBgColor
    }
    
    public func getBackgroundColor() -> SIMD4<Double> {
        return backgroundColor
    }
    
    public func getWaterColor() -> SIMD4<Float> {
        return waterColor
    }
    
    public func getLandCoverColor() -> SIMD4<Float> {
        return landCoverColor
    }
    
    public func getNorthPoleColor() -> SIMD4<Float> {
        return northPoleColor
    }
    
    public func getSouthPoleColor() -> SIMD4<Float> {
        return southPoleColor
    }
    
    init(tileBgColor: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0),
         backgroundColor: SIMD4<Double> = SIMD4<Double>(0.0039, 0.0431, 0.0980, 1.0),
         waterColor: SIMD4<Float> = SIMD4<Float>(0.3, 0.6, 0.9, 1.0),
         landCoverColor: SIMD4<Float> = SIMD4<Float>(0.4, 0.7, 0.4, 0.7)) {
        
        self.tileBgColor = tileBgColor
        self.backgroundColor = backgroundColor
        self.waterColor = waterColor
        self.landCoverColor = landCoverColor
        
        self.northPoleColor = self.waterColor
        self.southPoleColor = ColorsUtils.blend(source: self.landCoverColor, destination: self.tileBgColor)
    }
}


struct MapCameraSettings {
    fileprivate var z: Float
    fileprivate var latLon: SIMD2<Double> //55.74958790780624, 37.62346867711091
    fileprivate var rotationSensitivity: Float
    fileprivate var twoFingerPanSensitivity: Float
    fileprivate var panSensitivity: Float
    fileprivate var pinchSensitivity: Float
    fileprivate var maxCameraPitch: Float
    fileprivate var minCameraPitch: Float
    fileprivate var fov: Float
    fileprivate var nullZoomCameraDistance: Float
    fileprivate var minCameraDistance: Float
    fileprivate var farPlaneIncreaseFactor: Float
    fileprivate var zoomLevelMax: Float
    fileprivate var maxTileZoom: Int
    
    public func getZ() -> Float {
        return z
    }
    
    public func getLatLon() -> SIMD2<Double> {
        return latLon
    }
    
    public func getRotationSensitivity() -> Float {
        return rotationSensitivity
    }
    
    public func getTwoFingerPanSensitivity() -> Float {
        return twoFingerPanSensitivity
    }
    
    public func getPanSensitivity() -> Float {
        return panSensitivity
    }
    
    public func getPinchSensitivity() -> Float {
        return pinchSensitivity
    }
    
    public func getMaxCameraPitch() -> Float {
        return maxCameraPitch
    }
    
    public func getMinCameraPitch() -> Float {
        return minCameraPitch
    }
    
    public func getFov() -> Float {
        return fov
    }
    
    public func getNullZoomCameraDistance() -> Float {
        return nullZoomCameraDistance
    }
    
    public func getMinCameraDistance() -> Float {
        return minCameraDistance
    }
    
    public func getFarPlaneIncreaseFactor() -> Float {
        return farPlaneIncreaseFactor
    }
    
    public func getZoomLevelMax() -> Float {
        return zoomLevelMax
    }
    
    public func getMaxTileZoom() -> Int {
        return maxTileZoom
    }
    
    init(z: Float = 0,
         latLon: SIMD2<Double> = SIMD2<Double>(0, 0),
         rotationSensitivity: Float = 0.2,
         twoFingerPanSensitivity: Float = 0.003,
         panSensitivity: Float = 0.001,
         pinchSensitivity: Float = 0.1,
         maxCameraPitch: Float = Float.pi / 3,
         minCameraPitch: Float = 0,
         fov: Float = Float.pi / 3.0,
         farPlaneIncreaseFactor: Float = 2.0,
         zoomLevelMax: Float = 20.9,
         maxTileZoom: Int = 16) {
        self.maxTileZoom = maxTileZoom
        self.zoomLevelMax = zoomLevelMax
        self.farPlaneIncreaseFactor = farPlaneIncreaseFactor
        self.fov = fov
        self.z = z
        self.latLon = latLon
        self.rotationSensitivity = rotationSensitivity
        self.twoFingerPanSensitivity = twoFingerPanSensitivity
        self.panSensitivity = panSensitivity
        self.pinchSensitivity = pinchSensitivity
        self.maxCameraPitch = maxCameraPitch
        self.minCameraPitch = minCameraPitch
        
        nullZoomCameraDistance = 1.0 / (2 * tan(fov / 2))
        minCameraDistance = nullZoomCameraDistance / pow(2, 18)
    }
}


struct MapCommonSettings {
    fileprivate var forceRenderOnDisplayUpdate: Bool
    fileprivate let maxBuffersInFlight: Int
    fileprivate let seeTileInDirection: Int
    fileprivate let fetchTilesQueueCapacity: Int
    fileprivate let clearDownloadedOnDiskTiles: Bool
    fileprivate let spaceUnicodeNumber: Int
    fileprivate let spaceSize: Float
    fileprivate let maxConcurrentFetchs: Int
    fileprivate let maxCachedTilesCount: Int
    fileprivate let maxCachedTilesMemory: Int
    fileprivate let preferredFramesPerSecond: Int
    fileprivate let refreshLabelsIntersectionsEveryNDisplayLoop: UInt64
    fileprivate let maxInputComputeScreenPoints: Int
    fileprivate let labelsFadeAnimationTimeSeconds: Float
    fileprivate let buildingsFactor: Double
    fileprivate let roadLabelScreenSpacing: Float
    fileprivate let roadLabelTextSize: Float
    fileprivate let geoLabelsParametersBufferSize: Int
    fileprivate let globeTextureSize: Int
    fileprivate let globeToPlaneZoomStart: Float
    fileprivate let globeToPlaneZoomEnd: Float
    fileprivate let tileExtent: Int
    fileprivate let filterRoadLenLabel: Float
    fileprivate let nullZoomGlobeRadius: Float
    fileprivate let globeMapSize: Float
    fileprivate let baseFlatMapSize: Float
    
    public func getForceRenderOnDisplayUpdate() -> Bool {
        return forceRenderOnDisplayUpdate
    }
    
    public func getMaxBuffersInFlight() -> Int {
        return maxBuffersInFlight
    }
    
    public func getSeeTileInDirection() -> Int {
        return seeTileInDirection
    }
    
    public func getFetchTilesQueueCapacity() -> Int {
        return fetchTilesQueueCapacity
    }
    
    public func getClearDownloadedOnDiskTiles() -> Bool {
        return clearDownloadedOnDiskTiles
    }
    
    public func getSpaceUnicodeNumber() -> Int {
        return spaceUnicodeNumber
    }
    
    public func getSpaceSize() -> Float {
        return spaceSize
    }
    
    public func getMaxConcurrentFetchs() -> Int {
        return maxConcurrentFetchs
    }
    
    public func getMaxCachedTilesCount() -> Int {
        return maxCachedTilesCount
    }
    
    public func getMaxCachedTilesMemory() -> Int {
        return maxCachedTilesMemory
    }
    
    public func getPreferredFramesPerSecond() -> Int {
        return preferredFramesPerSecond
    }
    
    public func getRefreshLabelsIntersectionsEveryNDisplayLoop() -> UInt64 {
        return refreshLabelsIntersectionsEveryNDisplayLoop
    }
    
    public func getMaxInputComputeScreenPoints() -> Int {
        return maxInputComputeScreenPoints
    }
    
    public func getLabelsFadeAnimationTimeSeconds() -> Float {
        return labelsFadeAnimationTimeSeconds
    }
    
    public func getBuildingsFactor() -> Double {
        return buildingsFactor
    }
    
    public func getRoadLabelScreenSpacing() -> Float {
        return roadLabelScreenSpacing
    }
    
    public func getRoadLabelTextSize() -> Float {
        return roadLabelTextSize
    }
    
    public func getGeoLabelsParametersBufferSize() -> Int {
        return geoLabelsParametersBufferSize
    }
    
    public func getGlobeTextureSize() -> Int {
        return globeTextureSize
    }
    
    public func getGlobeToPlaneZoomStart() -> Float {
        return globeToPlaneZoomStart
    }
    
    public func getGlobeToPlaneZoomEnd() -> Float {
        return globeToPlaneZoomEnd
    }
    
    public func getTileExtent() -> Int {
        return tileExtent
    }
    
    public func getFilterRoadLenLabel() -> Float {
        return filterRoadLenLabel
    }
    
    public func getNullZoomGlobeRadius() -> Float {
        return nullZoomGlobeRadius
    }
    
    public func getGlobeMapSize() -> Float {
        return globeMapSize
    }
    
    public func getBaseFlatMapSize() -> Float {
        return baseFlatMapSize
    }
    
    init(
        forceRenderOnDisplayUpdate: Bool = false,
        maxBuffersInFlight: Int = 3,
        seeTileInDirection: Int = 2,
        fetchTilesQueueCapacity: Int = 40,
        clearDownloadedOnDiskTiles: Bool = false,
        spaceUnicodeNumber: Int = 32,
        spaceSize: Float = 0.2,
        maxConcurrentFetchs: Int = 3,
        maxCachedTilesCount: Int = 100,
        maxCachedTilesMemory: Int = 500 * 1024 * 1024,
        preferredFramesPerSecond: Int = 60,
        refreshLabelsIntersectionsEveryNDisplayLoop: UInt64 = 10,
        maxInputComputeScreenPoints: Int = 3000,
        labelsFadeAnimationTimeSeconds: Float = 0.3,
        buildingsFactor: Double = 0.006,
        roadLabelScreenSpacing: Float = 0,
        roadLabelTextSize: Float = 50,
        geoLabelsParametersBufferSize: Int = 40,
        globeTextureSize: Int = 4096 * 2,
        globeToPlaneZoomStart: Float = 4,
        globeToPlaneZoomEnd: Float = 5,
        tileExtent: Int = 4096,
        filterRoadLenLabel: Float = 0.3,
        nullZoomGlobeRadius: Float = 0.2,
        globeMapSize: Float = 1.0
    ) {
        self.forceRenderOnDisplayUpdate = forceRenderOnDisplayUpdate
        self.maxBuffersInFlight = maxBuffersInFlight
        self.seeTileInDirection = seeTileInDirection
        self.fetchTilesQueueCapacity = fetchTilesQueueCapacity
        self.clearDownloadedOnDiskTiles = clearDownloadedOnDiskTiles
        self.spaceUnicodeNumber = spaceUnicodeNumber
        self.spaceSize = spaceSize
        self.maxConcurrentFetchs = maxConcurrentFetchs
        self.maxCachedTilesCount = maxCachedTilesCount
        self.maxCachedTilesMemory = maxCachedTilesMemory
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.refreshLabelsIntersectionsEveryNDisplayLoop = refreshLabelsIntersectionsEveryNDisplayLoop
        self.maxInputComputeScreenPoints = maxInputComputeScreenPoints
        self.labelsFadeAnimationTimeSeconds = labelsFadeAnimationTimeSeconds
        self.buildingsFactor = buildingsFactor
        self.roadLabelScreenSpacing = roadLabelScreenSpacing
        self.roadLabelTextSize = roadLabelTextSize
        self.geoLabelsParametersBufferSize = geoLabelsParametersBufferSize
        self.globeTextureSize = globeTextureSize
        self.globeToPlaneZoomStart = globeToPlaneZoomStart
        self.globeToPlaneZoomEnd = globeToPlaneZoomEnd
        self.tileExtent = tileExtent
        self.filterRoadLenLabel = filterRoadLenLabel
        self.nullZoomGlobeRadius = nullZoomGlobeRadius
        self.globeMapSize = globeMapSize
        self.baseFlatMapSize = 2 * Float.pi * nullZoomGlobeRadius
    }
}


struct MapDebugSettings {
    fileprivate var drawBaseDebug: Bool
    fileprivate let addTestBorders: Bool
    fileprivate let cameraCenterPointSize: Float
    fileprivate let axisLength: Float
    fileprivate let axisThickness: Float
    fileprivate var drawAxis: Bool
    fileprivate var drawGrid: Bool
    fileprivate var printNotUsedStyle: Bool
    fileprivate var filterNotUsedLayernName: String
    fileprivate var debugAssemblingMap: Bool
    fileprivate let printCenterLatLon: Bool
    fileprivate let printCenterTile: Bool
    fileprivate let showOnlyTiles: [Tile]
    fileprivate let allowOnlyTiles: [Tile]
    fileprivate let getOnlySpecificMapLabels: [String]
    fileprivate let renderOnlyRoadsArray: [String]
    fileprivate let renderRoadArrayFromTo: [Int]
    fileprivate let drawRoadPointsDebug: Bool
    fileprivate let printVisibleTiles: Bool
    fileprivate let printVisibleAreaRange: Bool
    fileprivate let printRoadLabelsCount: Bool
    fileprivate let enabledThrottling: Bool
    fileprivate let throttlingNanoSeconds: UInt64
    fileprivate let drawTraversalPlane: Bool
    
    public func getDrawTraversalPlane() -> Bool {
        return drawTraversalPlane
    }
    
    public func getDrawBaseDebug() -> Bool {
        return drawBaseDebug
    }
    
    public func getAddTestBorders() -> Bool {
        return addTestBorders
    }
    
    public func getCameraCenterPointSize() -> Float {
        return cameraCenterPointSize
    }
    
    public func getAxisLength() -> Float {
        return axisLength
    }
    
    public func getAxisThickness() -> Float {
        return axisThickness
    }
    
    public func getDrawAxis() -> Bool {
        return drawAxis
    }
    
    public func getDrawGrid() -> Bool {
        return drawGrid
    }
    
    public func getPrintNotUsedStyle() -> Bool {
        return printNotUsedStyle
    }
    
    public func getFilterNotUsedLayernName() -> String {
        return filterNotUsedLayernName
    }
    
    public func getDebugAssemblingMap() -> Bool {
        return debugAssemblingMap
    }
    
    public func getPrintCenterLatLon() -> Bool {
        return printCenterLatLon
    }
    
    public func getPrintCenterTile() -> Bool {
        return printCenterTile
    }
    
    public func getShowOnlyTiles() -> [Tile] {
        return showOnlyTiles
    }
    
    public func getAllowOnlyTiles() -> [Tile] {
        return allowOnlyTiles
    }
    
    public func getGetOnlySpecificMapLabels() -> [String] {
        return getOnlySpecificMapLabels
    }
    
    public func getRenderOnlyRoadsArray() -> [String] {
        return renderOnlyRoadsArray
    }
    
    public func getRenderRoadArrayFromTo() -> [Int] {
        return renderRoadArrayFromTo
    }
    
    public func getDrawRoadPointsDebug() -> Bool {
        return drawRoadPointsDebug
    }
    
    public func getPrintVisibleTiles() -> Bool {
        return printVisibleTiles
    }
    
    public func getPrintVisibleAreaRange() -> Bool {
        return printVisibleAreaRange
    }
    
    public func getPrintRoadLabelsCount() -> Bool {
        return printRoadLabelsCount
    }
    
    public func getEnabledThrottling() -> Bool {
        return enabledThrottling
    }
    
    public func getThrottlingNanoSeconds() -> UInt64 {
        return throttlingNanoSeconds
    }

    init(
        enabled: Bool = false,
        addTestBorders: Bool = false,
        cameraCenterPointSize: Float = 0.01,
        axisLength: Float = 10_000,
        axisThickness: Float = 20,
        drawAxis: Bool = false,
        drawGrid: Bool = false,
        printNotUsedStyle: Bool = false,
        filterNotUsedLayernName: String = "road",
        debugAssemblingMap: Bool = false,
        printCenterLatLon: Bool = false,
        printCenterTile: Bool = false,
        showOnlyTiles: [Tile] = [],
        allowOnlyTiles: [Tile] = [],
        getOnlySpecificMapLabels: [String] = [],
        renderOnlyRoadsArray: [String] = [],
        renderRoadArrayFromTo: [Int] = [],
        drawRoadPointsDebug: Bool = false,
        printVisibleTiles: Bool = false,
        printVisibleAreaRange: Bool = false,
        printRoadLabelsCount: Bool = false,
        enabledThrottling: Bool = false,
        throttlingNanoSeconds: UInt64 = 4_000_000_000,
        drawTraversalPlane: Bool = false
    ) {
        self.drawBaseDebug = enabled
        self.addTestBorders = addTestBorders
        self.cameraCenterPointSize = cameraCenterPointSize
        self.axisLength = axisLength
        self.axisThickness = axisThickness
        self.drawAxis = drawAxis
        self.drawGrid = drawGrid
        self.printNotUsedStyle = printNotUsedStyle
        self.filterNotUsedLayernName = filterNotUsedLayernName
        self.debugAssemblingMap = debugAssemblingMap
        self.printCenterLatLon = printCenterLatLon
        self.printCenterTile = printCenterTile
        self.showOnlyTiles = showOnlyTiles
        self.allowOnlyTiles = allowOnlyTiles
        self.getOnlySpecificMapLabels = getOnlySpecificMapLabels
        self.renderOnlyRoadsArray = renderOnlyRoadsArray
        self.renderRoadArrayFromTo = renderRoadArrayFromTo
        self.drawRoadPointsDebug = drawRoadPointsDebug
        self.printVisibleTiles = printVisibleTiles
        self.printVisibleAreaRange = printVisibleAreaRange
        self.printRoadLabelsCount = printRoadLabelsCount
        self.enabledThrottling = enabledThrottling
        self.throttlingNanoSeconds = throttlingNanoSeconds
        self.drawTraversalPlane = drawTraversalPlane
    }
}
