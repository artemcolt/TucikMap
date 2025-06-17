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

    init() {
        fallbackStyle = FeatureStyle(
            key: fallbackKey,
            color: SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 100)
        )
    }
    
    func filterTextLabels(properties: [String: Sendable], tile: Tile) -> FilterTextLabelsResult? {
        guard let nameEn = properties["name_en"] as? String else {return nil}
        if Settings.getOnlySpecificMapLabels.isEmpty == false {
            if Settings.getOnlySpecificMapLabels.contains(nameEn) == false {
                return nil
            }
        }
        
        let filterRank = ushort(properties["filterrank"] as? UInt64 ?? 100)
        let sizeRank = ushort(properties["sizerank"] as? UInt64 ?? 20)
        let symbolRank = ushort(properties["symbolrank"] as? UInt64 ?? 20)
        //print("filterRank = \(filterRank), sizeRank = \(sizeRank), symbolRank = \(symbolRank), \(nameEn)")
        
        if (filterRank == 1) {
            return FilterTextLabelsResult(text: nameEn, scale: 65, sortRank: symbolRank)
        }
        
        if (tile.z <= 1 && filterRank <= 1) {
            return FilterTextLabelsResult(text: nameEn, scale: 60, sortRank: symbolRank)
        }
        
        if (tile.z <= 8 && filterRank <= 2) {
            return FilterTextLabelsResult(text: nameEn, scale: 60, sortRank: symbolRank)
        }
        
        if (tile.z <= 12 && filterRank <= 3) {
            return FilterTextLabelsResult(text: nameEn, scale: 60, sortRank: symbolRank)
        }
        
        if (tile.z <= 13 && filterRank <= 4) {
            return FilterTextLabelsResult(text: nameEn, scale: 60, sortRank: symbolRank)
        }
        
        if (tile.z <= 20 && filterRank <= 6) {
            return FilterTextLabelsResult(text: nameEn, scale: 60, sortRank: symbolRank)
        }
        
        
        return nil
    }
    
    func makeStyle(data: DetFeatureStyleData) -> FeatureStyle {
        let properties = data.properties
        let classValue = properties["class"] as? String

        // Color palette (RGBA, normalized to 0.0-1.0)
        let colors = [
            "admin_boundary": SIMD4<Float>(0.65, 0.65, 0.75, 1.0), // Soft purple-gray
            "admin_level_1": SIMD4<Float>(0.45, 0.55, 0.85, 1.0), // Deeper blue
            "water": SIMD4<Float>(0.3, 0.6, 0.9, 1.0),           // Light blue
            "river": SIMD4<Float>(0.2, 0.5, 0.8, 1.0),           // Slightly darker blue
            "landcover_forest": SIMD4<Float>(0.2, 0.6, 0.4, 0.7), // Forest green
            "landcover_grass": SIMD4<Float>(0.4, 0.7, 0.4, 0.7),  // Grass green
            "road_major": SIMD4<Float>(0.9, 0.9, 0.9, 1.0),       // Near-white
            "road_minor": SIMD4<Float>(0.7, 0.7, 0.7, 1.0),       // Light gray
            "building": SIMD4<Float>(0.8, 0.7, 0.6, 0.9),         // Warm beige
            "fallback": SIMD4<Float>(0.5, 0.5, 0.5, 0.5),          // Neutral gray
            "background": SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
        ]

        switch data.layerName {
        case "background":
            return FeatureStyle(
                key: 1,
                color: colors["background"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0)
            )
        case "landcover":
            if classValue == "forest" {
                return FeatureStyle(
                    key: 11, // Bottom layer, above fallback
                    color: colors["landcover_forest"]!,
                    parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0)
                )
            } else if classValue == "grass" {
                return FeatureStyle(
                    key: 12, // Above forest
                    color: colors["landcover_grass"]!,
                    parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0)
                )
            }
            return FeatureStyle(
                key: 10,
                color: colors["landcover_grass"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0)
            )

        case "water":
            if classValue == "river" {
                return FeatureStyle(
                    key: 21, // Above general water
                    color: colors["river"]!,
                    parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 3) // Thin line for rivers
                )
            }
            return FeatureStyle(
                key: 20, // Above landcover
                color: colors["water"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0) // Filled polygon
            )

        case "admin":
            if let adminLevel = properties["admin_level"] as? UInt64 {
                if adminLevel == 1 {
                    return FeatureStyle(
                        key: 102, // Above water
                        color: colors["admin_level_1"]!,
                        parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 8)
                    )
                } else if adminLevel == 2 {
                    return FeatureStyle(
                        key: 101,
                        color: colors["admin_boundary"]!,
                        parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 5)
                    )
                }
            }
            return FeatureStyle(
                key: 100,
                color: colors["admin_boundary"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 3)
            )

        case "road":
            if classValue == "highway" || classValue == "major_road" {
                return FeatureStyle(
                    key: 201, // Above admin
                    color: colors["road_major"]!,
                    parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 6)
                )
            } else {
                return FeatureStyle(
                    key: 200,
                    color: colors["road_minor"]!,
                    parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 6)
                )
            }

        case "building":
            return FeatureStyle(
                key: 210, // Topmost layer
                color: colors["building"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 0) // Filled polygon
            )

        default:
            return FeatureStyle(
                key: fallbackKey, // Bottom-most
                color: colors["fallback"]!,
                parseGeometryStyleData: ParseGeometryStyleData(lineWidth: 1)
            )
        }
    }
}
