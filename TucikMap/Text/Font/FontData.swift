//
//  FontData.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

struct Bounds: Decodable {
    var left: Float
    var top: Float
    var right: Float
    var bottom: Float
}

// Определение структур
struct GlyphData: Decodable {
    let unicode: Int
    let advance: Float
    let atlasBounds: Bounds?
    let planeBounds: Bounds?
}

struct Atlas: Decodable {
    let size: Float
    let width: Float
    let height: Float
    let yOrigin: String
}

struct FontData: Decodable {
    let atlas: Atlas
    let glyphs: [GlyphData]
}
