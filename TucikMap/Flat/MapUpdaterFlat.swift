//
//  AssembledMapUpdaterFlat.swift
//  TucikMap
//
//  Created by Artem on 7/26/25.
//

import MetalKit
import SwiftUI

class MapUpdaterFlat : MapUpdater {
    
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
        mapSettings: MapSettings
    ) {
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
                   updateBufferedUniform: updateBufferedUniform,
                   screenCollisionsDetector: screenCollisionsDetector,
                   mapSettings: mapSettings)
        
        metalTilesStorage.addHandler(handler: onMetalingTileEnd)
    }
    
    private func onMetalingTileEnd(tile: Tile) {
        if mapModeStorage.mapMode == .flat {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
}
