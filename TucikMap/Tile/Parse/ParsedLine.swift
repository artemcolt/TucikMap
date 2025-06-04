//
//  ParsedLine.swift
//  TucikMap
//
//  Created by Artem on 6/3/25.
//

struct ParsedLine {
    let points: [LinePoint]
}

struct ParsedLineRawVertices {
    let vertices: [SIMD2<Float>]
    let indices: [UInt32]
}
