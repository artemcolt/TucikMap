//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var drawLabelsFinal: DrawAssembledMap.DrawLabelsFinal?
    
    init(tiles: [MetalTile], labelsAssembled: DrawAssembledMap.DrawLabelsFinal?) {
        self.tiles = tiles
        self.drawLabelsFinal = labelsAssembled
    }
}
