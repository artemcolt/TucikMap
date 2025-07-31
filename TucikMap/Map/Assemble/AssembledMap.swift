//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class AssembledMap {
    var tiles: [MetalTile] { get { return _tiles }}
    var areaRange: AreaRange { get { return _areaRange }}
    var setTilesId: UInt { get { return _setTilesId }}
    var setAreaId: UInt { get { return _setAreaId }}
    
    private var _setTilesId: UInt = 0
    private var _setAreaId: UInt = 0
    
    private var _tiles: [MetalTile]
    private var _areaRange: AreaRange
    
    var tileGeoLabels: [MetalTile.TextLabels]
    var roadLabels: [DrawAssembledMap.FinalDrawRoadLabel]
    
    func isTilesStateChanged(compareId: UInt) -> Bool {
        return compareId != _setTilesId
    }
    
    func isAreaStateChanged(compareId: UInt) -> Bool {
        return compareId != _setAreaId
    }
    
    func setNewState(tiles: [MetalTile], areaRange: AreaRange) {
        self._tiles = tiles
        self._setTilesId += 1
        
        let sameRange = self._areaRange == areaRange
        if sameRange == false {
            self._setAreaId += 1
            self._areaRange = areaRange
        }
    }
    
    init(tiles: [MetalTile],
         areaRange: AreaRange,
         tileGeoLabels: [MetalTile.TextLabels],
         roadLabels: [DrawAssembledMap.FinalDrawRoadLabel],
    ) {
        self.tileGeoLabels = tileGeoLabels
        self.roadLabels = roadLabels
        self._tiles = tiles
        self._areaRange = areaRange
    }
}
