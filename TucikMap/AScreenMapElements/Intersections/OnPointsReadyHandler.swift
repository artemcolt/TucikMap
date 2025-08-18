//
//  OnPointsReadyHandler.swift
//  TucikMap
//
//  Created by Artem on 8/9/25.
//

import Foundation

class OnPointsReadyHandler {
    fileprivate let drawingFrameRequester   : DrawingFrameRequester
    fileprivate let handleGeoLabels         : HandleGeoLabels
    fileprivate let mapSettings             : MapSettings
    
    init(drawingFrameRequester: DrawingFrameRequester,
         handleGeoLabels: HandleGeoLabels,
         mapSettings: MapSettings) {
        self.drawingFrameRequester = drawingFrameRequester
        self.handleGeoLabels = handleGeoLabels
        self.mapSettings = mapSettings
    }
}

class OnPointsReadyHandlerGlobe : OnPointsReadyHandler {
    func onPointsReadyGlobe(resultGlobe: CombinedCompSPGlobe.ResultGlobe) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = resultGlobe
        let output = result.output.map { pos in HandleGeoLabels.Position(screenPos: pos.screenCoord, visible: pos.visibleGlobeSide) }
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        
        let spaceIntersections = SpaceIntersections()
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceIntersections: spaceIntersections)
        
        let labelsFadeAnimationTimeSeconds = mapSettings.getMapCommonSettings().getLabelsFadeAnimationTimeSeconds()
        drawingFrameRequester.renderNextNSeconds(Double(labelsFadeAnimationTimeSeconds))
        
        let end = CFAbsoluteTimeGetCurrent()
        let timeInterval = end - start
        //print(String(format: "Время выполнения: %.6f секунд", timeInterval))
    }
}

class OnPointsReadyHandlerFlat : OnPointsReadyHandler {
    fileprivate let handleRoadLabels : HandleRoadLabels
    
    init(drawingFrameRequester: DrawingFrameRequester,
         handleGeoLabels: HandleGeoLabels,
         handleRoadLabels: HandleRoadLabels,
         mapSettings: MapSettings) {
        self.handleRoadLabels = handleRoadLabels
        super.init(drawingFrameRequester: drawingFrameRequester, handleGeoLabels: handleGeoLabels, mapSettings: mapSettings)
    }
    
    func onPointsReadyFlat(resultFlat: CombinedCompSPFlat.ResultFlat) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = resultFlat.result
        let viewportSize = resultFlat.viewportSize
        let output = result.output.map { pos in HandleGeoLabels.Position(screenPos: pos, visible: true) }
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        
        let spaceIntersections = SpaceIntersections()
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceIntersections: spaceIntersections)
        
        let handleRoadInput = HandleRoadLabels.OnPointsReady(output: result.output,
                                                             uniforms: result.uniforms,
                                                             mapPanning: resultFlat.mapPanning,
                                                             mapSize: resultFlat.mapSize,
                                                             startRoadResultsIndex: resultFlat.startRoadResultsIndex,
                                                             metalRoadLabelsTiles: resultFlat.metalRoadLabelsTiles,
                                                             actualRoadLabelsIds: resultFlat.actualRoadLabelsIds)
        
        handleRoadLabels.onPointsReady(result: handleRoadInput, spaceIntersections: spaceIntersections, viewportSize: viewportSize)
        
        let labelsFadeAnimationTimeSeconds = mapSettings.getMapCommonSettings().getLabelsFadeAnimationTimeSeconds()
        drawingFrameRequester.renderNextNSeconds(Double(labelsFadeAnimationTimeSeconds))
        
        let end = CFAbsoluteTimeGetCurrent()
        let timeInterval = end - start
        //print(String(format: "Время выполнения: %.6f секунд", timeInterval))
    }
}
