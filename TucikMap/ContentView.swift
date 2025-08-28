//
//  ContentView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    let mapControllerCreated: MapControllerCreated = MapControllerCreated()
    let mapSettings: MapSettings
    
    init() {
        guard let mapboxToken = ProcessInfo.processInfo.environment["MAPBOX_TOKEN"] else {
            fatalError("MAPBOX_TOKEN environment variable is not set")
        }
        
        mapSettings = MapSettingsBuilder(getMapTileDownloadUrl: MapBoxGetMapTileUrl(accessToken: mapboxToken))
            .debugUI(enabled: true)
            .drawGrid(enabled: false)
            .renderOnDisplayUpdate(enabled: false)
            .style(mapStyle: DefaultMapStyle())
            .initPosition(z: 0.0, latLon: Locations.russia.coordinate) // SIMD2<Double>(0,0) Locations.russia.coordinate
            .initCameraPitch(0.0)
            .onContollerCreated(mapControllerCreated)
            .build()
    }
    
    var body: some View {
        TucikMapView(mapSettings: mapSettings)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
