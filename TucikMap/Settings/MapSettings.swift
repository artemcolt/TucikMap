//
//  MapSettings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

class MapSettings {
    var mapDebugSettings: MapDebugSettings {
        get {
            if _mapDebugSettings == nil {
                return MapDebugSettings(enabled: false, addTestBorders: false)
            }
            return _mapDebugSettings!
        }
    }
    
    let mapMoveSettings: MapMoveSettings
    let _mapDebugSettings: MapDebugSettings?
    
    init(mapMoveSettings: MapMoveSettings,
         mapDebugSettings: MapDebugSettings? = nil) {
        self.mapMoveSettings = mapMoveSettings
        self._mapDebugSettings = mapDebugSettings
    }
}
