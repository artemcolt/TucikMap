//
//  MetalRoadLabels.swift
//  TucikMap
//
//  Created by Artem on 7/15/25.
//

class MetalRoadLabels: Hashable {
    static func == (lhs: MetalRoadLabels, rhs: MetalRoadLabels) -> Bool {
        return lhs.tile.x == rhs.tile.x && lhs.tile.z == rhs.tile.z && lhs.tile.y == rhs.tile.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tile.x)
        hasher.combine(tile.y)
        hasher.combine(tile.z)
    }
    
    let tile: Tile
    let roadLabels: MapRoadLabelsAssembler.Result?
    var containIds: [UInt] = []
    
    var timePoint: Float? = nil
    
    init(
        tile: Tile,
        roadLabels: MapRoadLabelsAssembler.Result?,
    ) {
        self.tile = tile
        self.roadLabels = roadLabels
        guard let roadLabels = roadLabels else { return }
        self.containIds = roadLabels.mapLabelsCpuMeta.map { meta in meta.id }
    }
}
