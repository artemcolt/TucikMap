//
//  AssembledMapUpdaterFlat.swift
//  TucikMap
//
//  Created by Artem on 7/26/25.
//

import MetalKit
import SwiftUI

class MapUpdaterFlat : MapUpdater {
    private let screenCollisionsDetector: ScreenCollisionsDetector
    
    init(
        mapZoomState: MapZoomState,
        device: MTLDevice,
        camera: CameraFlatView,
        textTools: TextTools,
        drawingFrameRequester: DrawingFrameRequester,
        frameCounter: FrameCounter,
        metalTilesStorage: MetalTilesStorage,
        mapCadDisplayLoop: MapCADisplayLoop,
        mapModeStorage: MapModeStorage,
        mapUpdaterContext: MapUpdaterContext,
        screenCollisionsDetector: ScreenCollisionsDetector,
        updateBufferedUniform: UpdateBufferedUniform,
    ) {
        self.screenCollisionsDetector = screenCollisionsDetector
        super.init(mapZoomState: mapZoomState,
                   device: device,
                   camera: camera,
                   textTools: textTools,
                   drawingFrameRequester: drawingFrameRequester,
                   frameCounter: frameCounter,
                   metalTilesStorage: metalTilesStorage,
                   mapCadDisplayLoop: mapCadDisplayLoop,
                   mapModeStorage: mapModeStorage,
                   mapUpdaterContext: mapUpdaterContext,
                   updateBufferedUniform: updateBufferedUniform)
        
        metalTilesStorage.addHandler(handler: onMetalingTileEnd)
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        if mapModeStorage.mapMode == .flat {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
    
    override func updateActions(view: MTKView, actual: Set<MetalTile>, visibleTiles: [Tile]) {
        let allReady = actual.count == visibleTiles.count
        if allReady {
            screenCollisionsDetector.newState(actualTiles: Array(actual), view: view)
            mapCadDisplayLoop.forceUpdateStates()
        }
    }
}
