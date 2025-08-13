//
//  ContentView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    
    let mapMoveSettings = MapMoveSettings(enabled: false,
                                          z: 17,
                                          latLon: SIMD2<Double>(55.74958790780624, 37.62346867711091))
    
    let mapDebugSettings = MapDebugSettings(enabled: true, addTestBorders: true)
    
    var body: some View {
        TucikMapView(mapSettings: MapSettings(mapMoveSettings: mapMoveSettings, mapDebugSettings: mapDebugSettings))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
