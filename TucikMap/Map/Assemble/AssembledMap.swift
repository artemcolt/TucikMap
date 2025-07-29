//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var tileGeoLabels: [MetalTile.TextLabels]
    var roadLabels: [DrawAssembledMap.FinalDrawRoadLabel]
    
    
    init(tiles: [MetalTile],
         tileGeoLabels: [MetalTile.TextLabels],
         roadLabels: [DrawAssembledMap.FinalDrawRoadLabel],
    ) {
        self.tileGeoLabels = tileGeoLabels
        self.roadLabels = roadLabels
        self.tiles = tiles
    }
}
