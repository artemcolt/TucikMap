//
//  ReadingStageResult.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

struct ReadingStageResult {
    let polygon3dByStyle: [UInt8: [Parsed3dPolygon]]
    let polygonByStyle: [UInt8: [ParsedPolygon]]
    let rawLineByStyle: [UInt8: [ParsedLineRawVertices]]
    let styles: [UInt8: FeatureStyle]
    let textLabels: [ParsedTextLabel]
    let roadLabels: [ParsedRoadLabel]
}
