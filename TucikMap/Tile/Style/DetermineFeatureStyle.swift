//
//  FeatureStyle.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

class DetermineFeatureStyle {
    private let fallbackKey: UInt8 = 0
    private var stylesDictionary: [UInt8: FeatureStyle] = [:]
    private var fallbackStyle: FeatureStyle
    
    init() {
        fallbackStyle = FeatureStyle(key: fallbackKey, color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        createStylesMap()
    }
    
    func getStyle(key: UInt8) -> FeatureStyle {
        return stylesDictionary[key] ?? fallbackStyle
    }
    
    private func createStylesMap() {
        let waterKey = makeKey(data: DetFeatureStyleData(layerName: "water"))
        let landcoverKey = makeKey(data: DetFeatureStyleData(layerName: "landcover"))
        stylesDictionary[waterKey] = FeatureStyle(key: waterKey, color: SIMD4<Float>(0.0, 0.0, 1.0, 1.0))
        stylesDictionary[landcoverKey] = FeatureStyle(key: landcoverKey, color: SIMD4<Float>(0.5, 1.0, 0.5, 0.5))
        stylesDictionary[fallbackKey] = fallbackStyle
    }
    
    func determine(data: DetFeatureStyleData) -> FeatureStyle {
        let key = makeKey(data: data)
        return stylesDictionary[key] ?? fallbackStyle
    }
    
    private func makeKey(data: DetFeatureStyleData) -> UInt8 {
        if data.layerName == "water" {
            return 200
        }
        if data.layerName == "landcover" {
            return 1
        }
        return fallbackKey
    }
}
