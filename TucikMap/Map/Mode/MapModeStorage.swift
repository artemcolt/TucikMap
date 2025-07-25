//
//  MapModeStorage.swift
//  TucikMap
//
//  Created by Artem on 7/25/25.
//

class MapModeStorage {
    var mapMode: MapMode = .globe
    
    func switchState() {
        switch mapMode {
        case .flat:
            mapMode = .globe
        case .globe:
            mapMode = .flat
        }
    }
}
