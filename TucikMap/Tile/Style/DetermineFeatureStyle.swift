//
//  FeatureStyle.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

struct FilterTextLabelsResult {
    let text: String
    let scale: Float
    let sortRank: ushort
}

class DetermineFeatureStyle {
    private let fallbackKey: UInt8 = 0
    private var fallbackStyle: FeatureStyle
    private let mapSettings: MapSettings
    private let mapStyle: MapStyle

    init(mapSettings: MapSettings) {
        self.mapSettings = mapSettings
        fallbackStyle = FeatureStyle(
            key: fallbackKey,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 100)
        )
        
        mapStyle = mapSettings.getMapCommonSettings().getMapStyle()
    }
    
    func filterTextLabels(properties: [String: Sendable], tile: Tile) -> FilterTextLabelsResult? {
        return mapStyle.filterTextLabels(properties: properties, tile: tile)
    }
    
    func makeStyle(data: DetFeatureStyleData) -> FeatureStyle {
        return mapStyle.makeStyle(data: data)
    }
}
