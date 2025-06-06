//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//
import MetalKit

struct DrawingPolygonBytes {
    var vertices: [PolygonPipeline.VertexIn]
    var indices: [UInt32]
}

struct DrawingPolygonBuffers {
    var verticesBuffer: MTLBuffer
    var indicesBuffer: MTLBuffer
    var indicesCount: Int
}
