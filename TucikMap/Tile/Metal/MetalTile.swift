//
//  MetalTile.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import MetalKit


class MetalTile: Hashable {
    struct TextLabels {
        let textLabels: MapLabelsAssembler.Result?
        var containIds: [UInt] = []
        var timePoint: Float? = nil
        let tile: Tile
    }
    
    struct RoadLabels {
        let roadLabels: MapRoadLabelsAssembler.Result?
        var containIds: [UInt] = []
        var timePoint: Float? = nil
        let tile: Tile
    }
    
    static func == (lhs: MetalTile, rhs: MetalTile) -> Bool {
        return lhs.tile.x == rhs.tile.x && lhs.tile.z == rhs.tile.z && lhs.tile.y == rhs.tile.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tile.x)
        hasher.combine(tile.y)
        hasher.combine(tile.z)
    }
    
    let tile            : Tile
    let tile2dBuffers   : Tile2dBuffers
    let tile3dBuffers   : Tile3dBuffers
    
    var texts: TextLabels
    var roads: RoadLabels
    
    init(
        tile: Tile,
        tile2dBuffers: Tile2dBuffers,
        tile3dBuffers: Tile3dBuffers,
        
        textLabels: MapLabelsAssembler.Result?,
        roadLabels: MapRoadLabelsAssembler.Result?,
    ) {
        self.tile = tile
        self.tile2dBuffers = tile2dBuffers
        self.tile3dBuffers = tile3dBuffers
        
        // Метки городов и стран
        var textLabelsIds: [UInt] = []
        if let textLabels = textLabels {
            textLabelsIds = textLabels.mapLabelCpuMeta.map { meta in meta.id }
        }
        texts = TextLabels(textLabels: textLabels, containIds: textLabelsIds, tile: tile)
        
        // Метки названия улиц
        var roadLabelsIds: [UInt] = []
        if let roadLabels = roadLabels  {
            roadLabelsIds = roadLabels.mapLabelsCpuMeta.map { meta in meta.id }
        }
        roads = RoadLabels(roadLabels: roadLabels, containIds: roadLabelsIds, tile: tile)
    }
}
