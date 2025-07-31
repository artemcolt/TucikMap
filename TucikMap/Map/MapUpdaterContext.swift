//
//  MapUpdaterContext.swift
//  TucikMap
//
//  Created by Artem on 7/26/25.
//

class MapUpdaterContext {
    var assembledMap: AssembledMap = AssembledMap(
        tiles: [],
        areaRange: AreaRange(minX: -1, minY: -1, maxX: -1, maxY: -1, z: -1),
        tileGeoLabels: [],
        roadLabels: []
    )
}
