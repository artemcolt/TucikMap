//
//  unificationStageResult.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

struct UnificationStageResult {
    var drawingPolygon: DrawingPolygonBytes
    var styles: [TilePolygonStyle]
}

struct Unification3DStageResult {
    var drawingPolygon: Drawing3dPolygonBytes
    var styles: [TilePolygonStyle]
}
