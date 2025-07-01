//
//  ParsedPoint.swift
//  TucikMap
//
//  Created by Artem on 6/11/25.
//

import Foundation

struct ParsedTextLabel {
    let id: UInt
    let localPosition: SIMD2<Float>
    let nameEn: String
    let scale: Float
    let sortRank: ushort
}
