//
//  HandleGeoLabels.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit

class HandleGeoLabels {
    struct ForEvaluationResult {
        let recallLater: Bool
        let inputComputeScreenVertices: [InputComputeScreenVertex]
        let mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta]
        let modelMatrices: [matrix_float4x4]
        let metalGeoLabels: [MetalGeoLabels]
    }
    
    private let modelMatrixBufferSize = 60
    
    // самые актуальные надписи карты
    // для них мы считаем коллизии
    private var geoLabels: [MetalGeoLabels] = []
    private var geoLabelsTimePoints: [Float] = []
    private var actualLabelsIds: Set<UInt> = []
    
    private let frameCounter: FrameCounter
    private let mapZoomState: MapZoomState
    
    init(frameCounter: FrameCounter, mapZoomState: MapZoomState) {
        self.frameCounter = frameCounter
        self.mapZoomState = mapZoomState
    }
    
    func forEvaluateCollisions(
        mapPanning: SIMD3<Double>
    ) -> ForEvaluationResult {
        var inputComputeScreenVertices: [InputComputeScreenVertex] = []
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        var metalGeoLabels: [MetalGeoLabels] = []
        // Удаляет стухшие тайлы с гео метками
        for geoLabel in self.geoLabels {
            if geoLabel.timePoint == nil || elapsedTime - geoLabel.timePoint! < Settings.labelsFadeAnimationTimeSeconds {
                metalGeoLabels.append(geoLabel)
            }
        }
        self.geoLabels = metalGeoLabels
        if self.geoLabels.count > modelMatrixBufferSize {
            // если быстро зумить камеру туда/cюда то geoLabels будет расти в размере из-за того что анимация не успевает за изменениями
            // в таком случае пропускаем изменения и отображаем старые данные до тех пор пока пользователь не успокоиться
            //renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight) // продолжаем рендрить чтобы обновились данные в конце концов
            return ForEvaluationResult(
                recallLater: true,
                inputComputeScreenVertices: [],
                mapLabelLineCollisionsMeta: [],
                modelMatrices: [],
                metalGeoLabels: []
            ) // recompute is needed again but later
        }
        
        var modelMatrices = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        var mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta] = []
        for i in 0..<metalGeoLabels.count {
            let tile = metalGeoLabels[i]
            let tileModelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            modelMatrices[i] = tileModelMatrix
            
            guard let textLabels = tile.textLabels else { continue }
            let inputArray = textLabels.mapLabelLineCollisionsMeta.map {
                label in InputComputeScreenVertex(location: label.localPosition, matrixId: simd_short1(i))
            }
            inputComputeScreenVertices.append(contentsOf: inputArray)
            mapLabelLineCollisionsMeta.append(contentsOf: textLabels.mapLabelLineCollisionsMeta)
        }
        
        return ForEvaluationResult(
            recallLater: false,
            inputComputeScreenVertices: inputComputeScreenVertices,
            mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
            modelMatrices: modelMatrices,
            metalGeoLabels: metalGeoLabels
        )
    }
    
}
