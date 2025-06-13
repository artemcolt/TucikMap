//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile]
    var drawLabelsData: DrawMapLabelsData?
    var metaLines: [MapLabelLineMeta]
    
    init(tiles: [MetalTile], drawLabelsData: DrawMapLabelsData? = nil, metaLines: [MapLabelLineMeta]) {
        self.tiles = tiles
        self.drawLabelsData = drawLabelsData
        self.metaLines = metaLines
    }
}
