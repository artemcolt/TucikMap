//
//  MetalGeoLabels.swift
//  TucikMap
//
//  Created by Artem on 7/3/25.
//

import Foundation

class MetalGeoLabels: Hashable {
    static func == (lhs: MetalGeoLabels, rhs: MetalGeoLabels) -> Bool {
        return lhs.tile.x == rhs.tile.x && lhs.tile.z == rhs.tile.z && lhs.tile.y == rhs.tile.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tile.x)
        hasher.combine(tile.y)
        hasher.combine(tile.z)
    }
    
    let tile: Tile
    let textLabels: MapLabelsAssembler.Result?
    
    init(
        tile: Tile,
        textLabels: MapLabelsAssembler.Result?,
    ) {
        self.tile = tile
        self.textLabels = textLabels
    }
}
