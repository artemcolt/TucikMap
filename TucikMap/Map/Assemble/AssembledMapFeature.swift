//
//  AssembledGeometry.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

struct AssembledMapFeature {
    var featureStyle: FeatureStyle
    var verticesBuffer: MTLBuffer
    var indicesBuffer: MTLBuffer
    var vertexCount: Int
    var indexCount: Int
    var indexType: MTLIndexType
}

struct AssembledMapStyle {
    var featureStyle: FeatureStyle
}
