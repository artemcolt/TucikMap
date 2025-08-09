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
    func onPointsReadyGlobe(resultGlobe: CombinedCompSP.ResultGlobe) {
        let result = resultGlobe.result
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: result.output,
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
    
    func onPointsReadyFlat(resultFlat: CombinedCompSP.ResultFlat) {
        let result = resultFlat.result
        let viewportSize = resultFlat.viewportSize
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        let handleGeoInput = HandleGeoLabels.OnPointsReady(output: result.output,
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
