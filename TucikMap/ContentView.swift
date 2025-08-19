//
//  ContentView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    
    let mapSettings = MapSettingsBuilder()
        .initPosition(z: 0, latLon: SIMD2<Double>(0, 0))
        .debugUI(enabled: true)
        .renderOnDisplayUpdate(enabled: false)
        .build()
    
    var body: some View {
        TucikMapView(mapSettings: mapSettings)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
