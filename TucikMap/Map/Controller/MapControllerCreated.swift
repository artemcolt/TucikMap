//
//  MapControllerCreated.swift
//  TucikMap
//
//  Created by Artem on 8/24/25.
//

class MapControllerCreated: ControllerCreated {
    private(set) var mapController: MapController?
    
    func onControllerReady(mapController: MapController) {
        self.mapController = mapController
    }
}
