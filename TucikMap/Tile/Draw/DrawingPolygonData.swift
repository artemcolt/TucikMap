//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import MetalKit

struct DrawingPolygonData {
    var vertices: [SIMD2<Float>]
    var indices: [UInt16]
    var indicesBuffer: MTLBuffer
    var verticesBuffer: MTLBuffer
}


