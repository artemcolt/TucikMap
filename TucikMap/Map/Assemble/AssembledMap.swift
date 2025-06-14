//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var labelsAssembled: MapLabelsAssembler.Result?
    
    init(tiles: [MetalTile], labelsAssembled: MapLabelsAssembler.Result?) {
        self.tiles = tiles
        self.labelsAssembled = labelsAssembled
    }
}
