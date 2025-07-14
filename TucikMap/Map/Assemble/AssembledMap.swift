//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var tileGeoLabels: [MetalGeoLabels]
    var roadLabels: [MapRoadLabelsAssembler.DrawMapLabelsData]
    
    init(tiles: [MetalTile],
         tileGeoLabels:  [MetalGeoLabels],
         roadLabels: [MapRoadLabelsAssembler.DrawMapLabelsData]
    ) {
        self.tileGeoLabels = tileGeoLabels
        self.roadLabels = roadLabels
        self.tiles = tiles
    }
}
