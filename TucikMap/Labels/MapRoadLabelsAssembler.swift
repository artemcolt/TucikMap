//
//  MapRoadLabelsAssembler.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit


class MapRoadLabelsAssembler {
    struct StartRoadAt {
        let startAt: simd_float1
    }
    
    struct LineToStartAt {
        let index: simd_int1
        let count: simd_int1
    }
    
    struct MapLabelSymbolMeta {
        let lineMetaIndex: simd_int1
        let shiftX: simd_float1
    }

    struct MapLabelLineCollisionsMeta {
        let measuredText: MeasuredText
        let scale: simd_float1
        let localPosition: SIMD2<Float>
        let sortRank: ushort
        let id: UInt
    }

    struct MapLabelLineMeta {
        let measuredText: MeasuredText
        let scale: simd_float1
        let locationStartIndex: simd_int1
        let locationEndIndex: simd_int1
        let worldPathLen: simd_float1
    }
    
    struct DrawMapLabelsData {
        let vertexBuffer: MTLBuffer
        let mapLabelSymbolMeta: MTLBuffer
        let mapLabelLineMeta: MTLBuffer
        var intersectionsTrippleBuffer: [MTLBuffer]
        let verticesCount: Int
        let atlas: MTLTexture
        let localPositionsBuffer: MTLBuffer
        let startRoadAtBuffer: [MTLBuffer]
        let lineToStartFloatsBuffer: [MTLBuffer]
        var maxInstances: Int
    }

    struct DrawMapLabelsBytes {
        let vertices: [TextVertex]
        let mapLabelSymbolMeta: [MapLabelSymbolMeta]
        let mapLabelLineMeta: [MapLabelLineMeta]
        let verticesCount: Int
        let atlas: MTLTexture
        let mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta]
        let localPositions: [SIMD2<Float>]
    }
    
    struct Result {
        var drawMapLabelsData: DrawMapLabelsData
        var mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta]
    }
    
    struct TextLineData {
        let text: String
        let scale: Float
        let localPositions: [SIMD2<Float>]
        let id: UInt
        let sortRank: ushort
        let pathLen: Float
    }
    
    private let createTextGeometry: CreateTextGeometry
    private let metalDevice: MTLDevice
    private let frameCounter: FrameCounter
    
    init(createTextGeometry: CreateTextGeometry, metalDevice: MTLDevice, frameCounter: FrameCounter) {
        self.createTextGeometry = createTextGeometry
        self.metalDevice = metalDevice
        self.frameCounter = frameCounter
    }
    
    func assembleBytes(lines: [TextLineData], font: Font) -> DrawMapLabelsBytes {
        var mapLabelSymbolMeta: [MapLabelSymbolMeta] = []
        var mapLabelLineMeta: [MapLabelLineMeta] = []
        var mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta] = []
        var vertices: [TextVertex] = []
        var localPositions: [SIMD2<Float>] = []
        
        for i in 0..<lines.count {
            let line = lines[i]
                        
            let text = line.text
            let measuredText = createTextGeometry.measureText(text: text, fontData: font.fontData)
            let textVertices = createTextGeometry.createForRoadLabel(text: text, fontData: font.fontData, onGlyphCreated: { scalar, shiftX in
                mapLabelSymbolMeta.append(MapLabelSymbolMeta(
                    lineMetaIndex: simd_int1(i),
                    shiftX: shiftX
                ))
            })
            vertices.append(contentsOf: textVertices)
            
            let localPostionsStart = localPositions.count
            localPositions.append(contentsOf: line.localPositions)
            let localPostionsEnd = localPositions.count
            
            mapLabelLineMeta.append(MapLabelLineMeta(
                measuredText: measuredText,
                scale: line.scale,
                locationStartIndex: simd_int1(localPostionsStart),
                locationEndIndex: simd_int1(localPostionsEnd),
                worldPathLen: line.pathLen
            ))
            
            mapLabelLineCollisionsMeta.append(MapLabelLineCollisionsMeta(
                measuredText: measuredText,
                scale: line.scale,
                localPosition: SIMD2<Float>(0, 0),
                sortRank: line.sortRank,
                id: line.id
            ))
        }
        
        let verticesCount = vertices.count
        return DrawMapLabelsBytes(
            vertices: vertices,
            mapLabelSymbolMeta: mapLabelSymbolMeta,
            mapLabelLineMeta: mapLabelLineMeta,
            verticesCount: verticesCount,
            atlas: font.atlasTexture,
            mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
            localPositions: localPositions
        )
    }
    
    func assemble(lines: [TextLineData], font: Font) -> Result? {
        guard lines.isEmpty == false else { return nil }
        let assembledBytes = assembleBytes(lines: lines, font: font)
        
        let localPositionsBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.localPositions,
            length: MemoryLayout<SIMD2<Float>>.stride * assembledBytes.localPositions.count
        )!
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
        
        let startRoadAtSize = 20
        
        var intersectionsTrippleBuffer: [MTLBuffer] = []
        var startRoadAtTrippleBuffer: [MTLBuffer] = []
        var lineToStartFloatsTrippleBuffer: [MTLBuffer] = []
        for _ in 0..<3 {
            let intersectionsBuffer = metalDevice.makeBuffer(
                bytes: Array(repeating: LabelIntersection(hide: true, createdTime: 0), count: lines.count),
                length: MemoryLayout<LabelIntersection>.stride * lines.count
            )!
            intersectionsTrippleBuffer.append(intersectionsBuffer)
            
            let startRoadAtBuffer = metalDevice.makeBuffer(
                bytes: Array(repeating: StartRoadAt(startAt: 0), count: startRoadAtSize),
                length: MemoryLayout<StartRoadAt>.stride * startRoadAtSize
            )!
            startRoadAtTrippleBuffer.append(startRoadAtBuffer)
            
            let lineToStartFloatsBuffer = metalDevice.makeBuffer(
                bytes: Array(repeating: LineToStartAt(index: 0, count: 0), count: startRoadAtSize),
                length: MemoryLayout<LineToStartAt>.stride * startRoadAtSize
            )!
            lineToStartFloatsTrippleBuffer.append(lineToStartFloatsBuffer)
        }
        
        
        let drawData = DrawMapLabelsData(
            vertexBuffer: vertexBuffer,
            mapLabelSymbolMeta: mapLabelSymbolMetaBuffer,
            mapLabelLineMeta: mapLabelLineMetaBuffer,
            intersectionsTrippleBuffer: intersectionsTrippleBuffer,
            verticesCount: assembledBytes.verticesCount,
            atlas: assembledBytes.atlas,
            localPositionsBuffer: localPositionsBuffer,
            startRoadAtBuffer: startRoadAtTrippleBuffer,
            lineToStartFloatsBuffer: lineToStartFloatsTrippleBuffer,
            maxInstances: 0
        )
        return Result(drawMapLabelsData: drawData, mapLabelLineCollisionsMeta: assembledBytes.mapLabelLineCollisionsMeta)
    }
}
