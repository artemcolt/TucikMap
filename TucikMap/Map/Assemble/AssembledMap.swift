//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var drawLabelsFinal: MapLabelsMaker.DrawLabelsFinal?
    
    init(tiles: [MetalTile], labelsAssembled: MapLabelsMaker.DrawLabelsFinal?) {
        self.tiles = tiles
        self.drawLabelsFinal = labelsAssembled
    }
}
