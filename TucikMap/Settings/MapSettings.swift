//
//  MapSettings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

class MapSettings {
    let mapMoveSettings: MapMoveSettings
    let mapDebugSettings: MapDebugSettings?
    
    init(mapMoveSettings: MapMoveSettings,
         mapDebugSettings: MapDebugSettings? = nil) {
        self.mapMoveSettings = mapMoveSettings
        self.mapDebugSettings = mapDebugSettings
    }
}
