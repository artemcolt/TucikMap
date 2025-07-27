//
//  MapUpdaterGlobe.swift
//  TucikMap
//
//  Created by Artem on 7/26/25.
//

import MetalKit
import SwiftUI

class MapUpdaterGlobe : MapUpdater {
    private let globeTexturing: GlobeTexturing
    
    init(mapZoomState: MapZoomState,
         device: MTLDevice,
         camera: Camera,
         textTools: TextTools,
         drawingFrameRequester: DrawingFrameRequester,
         frameCounter: FrameCounter,
         metalTilesStorage: MetalTilesStorage,
         mapCadDisplayLoop: MapCADisplayLoop,
         mapModeStorage: MapModeStorage,
         mapUpdaterContext: MapUpdaterContext,
         updateBufferedUniform: UpdateBufferedUniform,
         globeTexturing: GlobeTexturing) {
        self.globeTexturing = globeTexturing
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
        if mapModeStorage.mapMode == .globe {
            self.update(view: savedView, useOnlyCached: true)
        }
    }
    
    override func updateActions(view: MTKView,
                                actual: Set<MetalTile>,
                                visibleTiles: [Tile]) {
        globeTexturing.setTiles(tiles: Array(actual))
    }
}
