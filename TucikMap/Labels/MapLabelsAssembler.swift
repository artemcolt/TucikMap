//
//  MapLabelsAssembler.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//
import MetalKit

struct DrawMapLabelsData {
    let vertexBuffer: MTLBuffer
    let mapLabelSymbolMeta: MTLBuffer
    let mapLabelLineMeta: MTLBuffer
    var intersectionsTrippleBuffer: [MTLBuffer]
    let verticesCount: Int
    let atlas: MTLTexture
}

struct DrawMapLabelsBytes {
    let vertices: [TextVertex]
    let mapLabelSymbolMeta: [MapLabelSymbolMeta]
    let mapLabelLineMeta: [MapLabelLineMeta]
    let verticesCount: Int
    let atlas: MTLTexture
}

class MapLabelsAssembler {
    private let createTextGeometry: CreateTextGeometry
    private let metalDevice: MTLDevice
    private let frameCounter: FrameCounter
    
    init(createTextGeometry: CreateTextGeometry, metalDevice: MTLDevice, frameCounter: FrameCounter) {
        self.createTextGeometry = createTextGeometry
        self.metalDevice = metalDevice
        self.frameCounter = frameCounter
    }
    
    struct TextLineData {
        let text: String
        let scale: Float
        let localPosition: SIMD2<Float>
    }
    
    func assembleBytes(lines: [TextLineData], font: Font) -> DrawMapLabelsBytes {
        var mapLabelSymbolMeta: [MapLabelSymbolMeta] = []
        var mapLabelLineMeta: [MapLabelLineMeta] = []
        var vertices: [TextVertex] = []
        
        for i in 0..<lines.count {
            let line = lines[i]
            let text = line.text
            let measuredText = createTextGeometry.measureText(text: text, fontData: font.fontData)
            let textVertices = createTextGeometry.create(text: text, fontData: font.fontData, onGlyphCreated: { scalar in
                mapLabelSymbolMeta.append(MapLabelSymbolMeta(
                    lineMetaIndex: simd_int1(i)
                ))
            })
            vertices.append(contentsOf: textVertices)
            
            mapLabelLineMeta.append(MapLabelLineMeta(
                measuredText: measuredText,
                scale: line.scale,
                localPosition: line.localPosition
            ))
        }
        
        let verticesCount = vertices.count
        return DrawMapLabelsBytes(
            vertices: vertices,
            mapLabelSymbolMeta: mapLabelSymbolMeta,
            mapLabelLineMeta: mapLabelLineMeta,
            verticesCount: verticesCount,
            atlas: font.atlasTexture,
        )
    }
    
    struct Result {
        var drawMapLabelsData: DrawMapLabelsData
        var metaLines: [MapLabelLineMeta]
    }
    
    func assemble(lines: [TextLineData], font: Font) -> Result? {
        guard lines.isEmpty == false else { return nil }
        let assembledBytes = assembleBytes(lines: lines, font: font)
        
        let vertexBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.vertices,
            length: MemoryLayout<TextVertex>.stride * assembledBytes.verticesCount
        )!
        let mapLabelSymbolMetaBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.mapLabelSymbolMeta,
            length: MemoryLayout<MapLabelSymbolMeta>.stride * assembledBytes.mapLabelSymbolMeta.count
        )!
        let mapLabelLineMetaBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.mapLabelLineMeta,
            length: MemoryLayout<MapLabelLineMeta>.stride * assembledBytes.mapLabelLineMeta.count
        )!
        var intersectionsTrippleBuffer: [MTLBuffer] = []
        for _ in 0..<3 {
            let intersectionsBuffer = metalDevice.makeBuffer(
                bytes: Array(repeating: LabelIntersection(hide: true, createdTime: 0), count: lines.count),
                length: MemoryLayout<LabelIntersection>.stride * lines.count
            )!
            intersectionsTrippleBuffer.append(intersectionsBuffer)
        }
        
        let drawData = DrawMapLabelsData(
            vertexBuffer: vertexBuffer,
            mapLabelSymbolMeta: mapLabelSymbolMetaBuffer,
            mapLabelLineMeta: mapLabelLineMetaBuffer,
            intersectionsTrippleBuffer: intersectionsTrippleBuffer,
            verticesCount: assembledBytes.verticesCount,
            atlas: assembledBytes.atlas
        )
        return Result(drawMapLabelsData: drawData, metaLines: assembledBytes.mapLabelLineMeta)
    }
}
