//
//  ContentView.swift
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

import SwiftUI

let MAPBOX_TOKEN: String = "pk.eyJ1IjoiaW52ZWN0eXMiLCJhIjoiY2w0emRzYWx5MG1iMzNlbW91eWRwZzdldCJ9.EAByLTrB_zc7-ytI6GDGBw"

struct ContentView: View {
    let mapSettings = MapSettingsBuilder(getMapTileDownloadUrl: MapBoxGetMapTileUrl(accessToken: MAPBOX_TOKEN)).build()
    
    var body: some View {
        TucikMapView(mapSettings: mapSettings)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
