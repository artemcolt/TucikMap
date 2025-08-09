//
//  OnPointsReadyHandler.swift
//  TucikMap
//
//  Created by Artem on 8/9/25.
//

class OnPointsReadyHandler {
    fileprivate let drawingFrameRequester   : DrawingFrameRequester
    fileprivate let handleGeoLabels         : HandleGeoLabels
    
    init(drawingFrameRequester: DrawingFrameRequester,
         handleGeoLabels: HandleGeoLabels) {
        self.drawingFrameRequester = drawingFrameRequester
        self.handleGeoLabels = handleGeoLabels
    }
}

class OnPointsReadyHandlerGlobe : OnPointsReadyHandler {
    func onPointsReadyGlobe(resultGlobe: CombinedCompSPGlobe.ResultGlobe) {
        let result = resultGlobe
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let output = result.output.map { pos in HandleGeoLabels.Position(screenPos: pos.screenCoord, visible: pos.visibleGlobeSide) }
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceDiscretisation: spaceDiscretisation)
        
        drawingFrameRequester.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
    }
}

class OnPointsReadyHandlerFlat : OnPointsReadyHandler {
    fileprivate let handleRoadLabels : HandleRoadLabels
    
    init(drawingFrameRequester: DrawingFrameRequester,
         handleGeoLabels: HandleGeoLabels,
         handleRoadLabels: HandleRoadLabels) {
        self.handleRoadLabels = handleRoadLabels
        super.init(drawingFrameRequester: drawingFrameRequester, handleGeoLabels: handleGeoLabels)
    }
    
    func onPointsReadyFlat(resultFlat: CombinedCompSPFlat.ResultFlat) {
        let result = resultFlat.result
        let viewportSize = resultFlat.viewportSize
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let output = result.output.map { pos in HandleGeoLabels.Position(screenPos: pos, visible: true) }
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: output,
                                                           metalGeoLabels: result.metalGeoLabels,
                                                           mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                           actualLabelsIds: result.actualLabelsIds,
                                                           geoLabelsSize: result.geoLabelsSize)
        
        handleGeoLabels.onPointsReady(input: handleGeoInput, spaceDiscretisation: spaceDiscretisation)
        
        let handleRoadInput = HandleRoadLabels.OnPointsReady(output: result.output,
                                                             uniforms: result.uniforms,
                                                             mapPanning: resultFlat.mapPanning,
                                                             mapSize: resultFlat.mapSize,
                                                             startRoadResultsIndex: resultFlat.startRoadResultsIndex,
                                                             metalRoadLabelsTiles: resultFlat.metalRoadLabelsTiles,
                                                             actualRoadLabelsIds: resultFlat.actualRoadLabelsIds)
        
        handleRoadLabels.onPointsReady(result: handleRoadInput, spaceDiscretisation: spaceDiscretisation, viewportSize: viewportSize)
        
        
        drawingFrameRequester.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
    }
}
