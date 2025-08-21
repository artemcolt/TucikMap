//
//  MapSettings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import SwiftUI
import MetalKit

class MapSettingsBuilder {
    private var mapCameraSettings = MapCameraSettings()
    private var mapDebugSettings = MapDebugSettings()
    private var mapCommonSettings = MapCommonSettings()
    
    public func getMapCameraSettings() -> MapCameraSettings {
        return mapCameraSettings
    }
    
    func capsFadeZooms(startZ: Float, endZ: Float) -> MapSettingsBuilder {
        mapCommonSettings.fadeCapsStartZ = startZ
        mapCommonSettings.fadeCapsEndZ = endZ
        return self
    }
    
    func tileDownloadUrlAdapter(getMapTileDownloadUrl: GetMapTileDownloadUrl) -> MapSettingsBuilder {
        mapCommonSettings.getMapTileDownloadUrl = getMapTileDownloadUrl
        return self
    }
    
    func maxCachedTilesMemInBytes(memInBytes: Int) -> MapSettingsBuilder {
        mapCommonSettings.maxCachedTilesMemInBytes = memInBytes
        return self
    }
    
    func showLabelsOnTilesDist(tilesDist: Int) -> MapSettingsBuilder {
        mapCommonSettings.showLabelsOnTilesDist = tilesDist
        return self
    }
    
    func drawTraversalPlane(enabled: Bool) -> MapSettingsBuilder {
        mapDebugSettings.drawTraversalPlane = enabled
        return self
    }
    
    func visionSizeGlobe(tiles: Int) -> MapSettingsBuilder {
        let getFTQCapacityFor = MapCommonSettings.getFTQCapacityFor
        mapCommonSettings.seeTileInDirectionGlobe = tiles
        mapCommonSettings.fetchTilesQueueCapacity = max(getFTQCapacityFor(tiles), getFTQCapacityFor(mapCommonSettings.seeTileInDirectionFlat))
        return self
    }
    
    func visionSizeFlat(tiles: Int) -> MapSettingsBuilder {
        let getFTQCapacityFor = MapCommonSettings.getFTQCapacityFor
        mapCommonSettings.seeTileInDirectionFlat = tiles
        mapCommonSettings.fetchTilesQueueCapacity = max(getFTQCapacityFor(tiles), getFTQCapacityFor(mapCommonSettings.seeTileInDirectionGlobe))
        return self
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
    
    func drawGrid(enabled: Bool) -> MapSettingsBuilder {
        mapDebugSettings.addTestBorders = enabled
        return self
    }
    
    func drawTileBorders(enabled: Bool) -> MapSettingsBuilder {
        mapDebugSettings.drawBaseDebug = enabled
        return self
    }
    
    func renderOnDisplayUpdate(enabled: Bool) -> MapSettingsBuilder {
        mapCommonSettings.forceRenderOnDisplayUpdate = enabled
        return self
    }
    
    func debugAssemblingMap(enabled: Bool) -> MapSettingsBuilder {
        mapDebugSettings.debugAssemblingMap = enabled
        return self
    }
    
    func build() -> MapSettings {
        return MapSettings(mapCameraSettings: mapCameraSettings,
                           mapDebugSettings: mapDebugSettings,
                           mapCommonSettings: mapCommonSettings)
    }
    
    init(getMapTileDownloadUrl: GetMapTileDownloadUrl) {
        mapCommonSettings.getMapTileDownloadUrl = getMapTileDownloadUrl
    }
}



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
    fileprivate var nullZoomCameraDistance: Float
    fileprivate var minCameraDistance: Float
    fileprivate var farPlaneIncreaseFactor: Float
    fileprivate var zoomLevelMax: Float
    fileprivate var maxTileZoom: Int
    
    fileprivate var baseFov: Float
    fileprivate var poleFov: Float
    
    fileprivate var camAffectDistStartZ: Float
    fileprivate var camAffectDistEndZ: Float
    
    public func getCamAffectDistStartZ() -> Float {
        return camAffectDistStartZ
    }
    
    public func getCamAffectDistEndZ() -> Float {
        return camAffectDistEndZ
    }
    
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
    
    public func getBaseFov() -> Float {
        return baseFov
    }
    
    public func getPoleFov() -> Float {
        return poleFov
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
         farPlaneIncreaseFactor: Float = 2.0,
         zoomLevelMax: Float = 20.9,
         maxTileZoom: Int = 16,
         baseFov: Float = Float.pi / 3.0,
         poleFov: Float = Float.pi / 6.0,
         camAffectDistStartZ: Float = 1,
         camAffectDistEndZ: Float = 3,
    ) {
        self.maxTileZoom = maxTileZoom
        self.zoomLevelMax = zoomLevelMax
        self.farPlaneIncreaseFactor = farPlaneIncreaseFactor
        self.z = z
        self.latLon = latLon
        self.rotationSensitivity = rotationSensitivity
        self.twoFingerPanSensitivity = twoFingerPanSensitivity
        self.panSensitivity = panSensitivity
        self.pinchSensitivity = pinchSensitivity
        self.maxCameraPitch = maxCameraPitch
        self.minCameraPitch = minCameraPitch
        self.camAffectDistStartZ = camAffectDistStartZ
        self.camAffectDistEndZ = camAffectDistEndZ
        
        self.baseFov = baseFov
        self.poleFov = poleFov
        
        nullZoomCameraDistance = 1.0 / (2 * tan(baseFov / 2))
        minCameraDistance = nullZoomCameraDistance / pow(2, 18)
    }
}


struct MapCommonSettings {
    fileprivate var forceRenderOnDisplayUpdate: Bool
    fileprivate let maxBuffersInFlight: Int
    fileprivate var seeTileInDirectionGlobe: Int
    fileprivate var seeTileInDirectionFlat: Int
    fileprivate let clearDownloadedOnDiskTiles: Bool
    fileprivate let spaceUnicodeNumber: Int
    fileprivate let spaceSize: Float
    fileprivate let maxConcurrentFetchs: Int
    fileprivate var maxCachedTilesMemInBytes: Int
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
    fileprivate var fetchTilesQueueCapacity: Int
    fileprivate var showLabelsOnTilesDist: Int
    fileprivate var getMapTileDownloadUrl: GetMapTileDownloadUrl
    fileprivate var fadeCapsStartZ: Float
    fileprivate var fadeCapsEndZ: Float
    
    public func GetGetMapTileDownloadUrl() -> GetMapTileDownloadUrl {
        return getMapTileDownloadUrl
    }
    
    public func getFadeCapsStartZ() -> Float {
        return fadeCapsStartZ
    }
    
    public func getFadeCapsEndZ() -> Float {
        return fadeCapsEndZ
    }
    
    public func getShowLabelsOnTilesDist() -> Int {
        return showLabelsOnTilesDist
    }
    
    public func getForceRenderOnDisplayUpdate() -> Bool {
        return forceRenderOnDisplayUpdate
    }
    
    public func getMaxBuffersInFlight() -> Int {
        return maxBuffersInFlight
    }
    
    public func getSeeTileInDirectionGlobe() -> Int {
        return seeTileInDirectionGlobe
    }
    
    public func getSeeTileInDirectionFlat() -> Int {
        return seeTileInDirectionFlat
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
    
    public func getMaxCachedTilesMemInBytes() -> Int {
        return maxCachedTilesMemInBytes
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
        seeTileInDirectionFlat: Int = 3,
        seeTileInDirectionGlobe: Int = 2,
        clearDownloadedOnDiskTiles: Bool = false,
        spaceUnicodeNumber: Int = 32,
        spaceSize: Float = 0.2,
        maxConcurrentFetchs: Int = 3,
        maxCachedTilesMemory: Int = 500 * 1024 * 1024,
        preferredFramesPerSecond: Int = 60,
        refreshLabelsIntersectionsEveryNDisplayLoop: UInt64 = 10,
        labelsFadeAnimationTimeSeconds: Float = 0.3,
        buildingsFactor: Double = 0.006,
        roadLabelScreenSpacing: Float = 0,
        roadLabelTextSize: Float = 50,
        maxInputComputeScreenPoints: Int = 6000,
        geoLabelsParametersBufferSize: Int = 200,
        globeTextureSize: Int = 4096 * 2,
        globeToPlaneZoomStart: Float = 6,
        globeToPlaneZoomEnd: Float = 7,
        tileExtent: Int = 4096,
        filterRoadLenLabel: Float = 0.3,
        nullZoomGlobeRadius: Float = 0.2,
        globeMapSize: Float = 1.0,
        showLabelsOnTilesDist: Int = 1,
        getMapTileDownloadUrl: GetMapTileDownloadUrl = MapBoxGetMapTileUrl(accessToken: ""),
        fadeCapsStartZ: Float = 4,
        fadeCapsEndZ: Float = 5
    ) {
        self.forceRenderOnDisplayUpdate = forceRenderOnDisplayUpdate
        self.maxBuffersInFlight = maxBuffersInFlight
        self.seeTileInDirectionFlat = seeTileInDirectionFlat
        self.seeTileInDirectionGlobe = seeTileInDirectionGlobe
        self.clearDownloadedOnDiskTiles = clearDownloadedOnDiskTiles
        self.spaceUnicodeNumber = spaceUnicodeNumber
        self.spaceSize = spaceSize
        self.maxConcurrentFetchs = maxConcurrentFetchs
        self.maxCachedTilesMemInBytes = maxCachedTilesMemory
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
        self.showLabelsOnTilesDist = showLabelsOnTilesDist
        self.getMapTileDownloadUrl = getMapTileDownloadUrl
        self.fadeCapsStartZ = fadeCapsStartZ
        self.fadeCapsEndZ = fadeCapsEndZ
        self.baseFlatMapSize = 2 * Float.pi * nullZoomGlobeRadius
        
        let getFTQCapacityFor = MapCommonSettings.getFTQCapacityFor
        self.fetchTilesQueueCapacity = max(getFTQCapacityFor(seeTileInDirectionGlobe), getFTQCapacityFor(seeTileInDirectionFlat))
    }
    
    // get fetch tiles queue capacity for visible size
    static func getFTQCapacityFor(_ seeInDirection: Int) -> Int {
        let res = pow(Float(seeInDirection + seeInDirection + 1), 2) // столько тайлов на границе
        return Int(res)
    }
}


struct MapDebugSettings {
    fileprivate var drawBaseDebug: Bool
    fileprivate var addTestBorders: Bool
    fileprivate let cameraCenterPointSize: Float
    fileprivate let axisLength: Float
    fileprivate let axisThickness: Float
    fileprivate var drawAxis: Bool
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
    fileprivate var drawTraversalPlane: Bool
    
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
        drawBaseDebug: Bool = false,
        addTestBorders: Bool = false,
        cameraCenterPointSize: Float = 0.01,
        axisLength: Float = 10_000,
        axisThickness: Float = 20,
        drawAxis: Bool = false,
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
        self.drawBaseDebug = drawBaseDebug
        self.addTestBorders = addTestBorders
        self.cameraCenterPointSize = cameraCenterPointSize
        self.axisLength = axisLength
        self.axisThickness = axisThickness
        self.drawAxis = drawAxis
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
