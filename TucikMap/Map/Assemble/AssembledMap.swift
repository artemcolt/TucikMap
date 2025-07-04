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
    
    init(tiles: [MetalTile], tileGeoLabels:  [MetalGeoLabels]) {
        self.tileGeoLabels = tileGeoLabels
        self.tiles = tiles
    }
}
