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

    // Эта мета нужна чтобы считать на CPU всю нужную информацию
    struct MapLabelCpuMeta {
        let measuredText        : MeasuredText
        let scale               : simd_float1
        let localPositions      : [SIMD2<Float>]
        let sortRank            : ushort
        let id                  : UInt
        let pathLen             : Float
        let glyphShifts         : [Float]
    }

    // Эта мета нужна чтобы считать внутри шейдера
    struct MapLabelGpuMeta {
        let measuredText        : MeasuredText
        let scale               : simd_float1
        let locationStartIndex  : simd_int1
        let locationEndIndex    : simd_int1
        let worldPathLen        : simd_float1
        let isVertical          : simd_bool
        let negativeDirection   : simd_bool
    }
    
    // Для отрисовки всех меток одного тайла
    struct MetalDrawMapLabels {
        let vertexBuffer                    : MTLBuffer
        let mapLabelSymbolMeta              : MTLBuffer
        let mapLabelGpuMeta                 : MTLBuffer
        var intersectionsTrippleBuffer      : [MTLBuffer]
        let verticesCount                   : Int
        let atlas                           : MTLTexture
        let localPositionsBuffer            : MTLBuffer
        let startRoadAtBuffer               : [MTLBuffer]
        let lineToStartFloatsBuffer         : [MTLBuffer]
    }

    // Для отрисвки всех меток одного тайла, но в виде массивов
    struct DrawMapLabels {
        let vertices                    : [TextVertex]
        let mapLabelSymbolMeta          : [MapLabelSymbolMeta]
        let mapLabelGpuMeta             : [MapLabelGpuMeta]
        let verticesCount               : Int
        let atlas                       : MTLTexture
        let mapLabelCpuMeta             : [MapLabelCpuMeta]
        let localPositions              : [LocalPosition]
    }
    
    struct Result {
        var draw                : MetalDrawMapLabels
        var mapLabelsCpuMeta    : [MapLabelCpuMeta]
    }
    
    struct TextLineData {
        let text            : String
        let scale           : Float
        let localPositions  : [SIMD2<Float>]
        let id              : UInt
        let sortRank        : ushort
        let pathLen         : Float
    }
    
    struct LocalPosition {
        let position: SIMD2<Float>
    }
    
    private let metalDevice         : MTLDevice
    private let createTextGeometry  : CreateTextGeometry
    private let frameCounter        : FrameCounter
    
    init(createTextGeometry: CreateTextGeometry, metalDevice: MTLDevice, frameCounter: FrameCounter) {
        self.createTextGeometry     = createTextGeometry
        self.metalDevice            = metalDevice
        self.frameCounter           = frameCounter
    }
    
    private func createArrays(lines: [TextLineData], font: Font) -> DrawMapLabels {
        var mapLabelSymbolMeta          : [MapLabelSymbolMeta] = []
        var mapLabelGpuMeta             : [MapLabelGpuMeta] = []
        var mapLabelCpuMeta             : [MapLabelCpuMeta] = []
        var vertices                    : [TextVertex] = []
        var localPositions              : [LocalPosition] = []
        
        for i in 0..<lines.count {
            let line                = lines[i]
            var glyphShifts         : [Float] = []
            
            glyphShifts.reserveCapacity(line.text.count)
            func onGlyphCreated(scalar: Unicode.Scalar, shift: Float) {
                mapLabelSymbolMeta.append(MapLabelSymbolMeta(lineMetaIndex: simd_int1(i), shiftX: shift))
                glyphShifts.append(shift)
            }
            
            let text                = line.text
            let measuredText        = createTextGeometry.measureText(text: text, fontData: font.fontData)
            let textVertices        = createTextGeometry.createForRoadLabel(text: text, fontData: font.fontData, onGlyphCreated: onGlyphCreated)
            vertices.append(contentsOf: textVertices)
            
            var fullDeltaX          = Float(0)
            var fullDeltaY          = Float(0)
            for i in 0..<line.localPositions.count-1 {
                let current     = line.localPositions[i]
                let next        = line.localPositions[i + 1]
                let deltaX      = next.x - current.x
                let deltaY      = next.y - current.y
                fullDeltaX      += deltaX
                fullDeltaY      += deltaY
            }
            
            let localPostionsStart  = localPositions.count
            localPositions.append(contentsOf: line.localPositions.map { pos in LocalPosition(position: pos) })
            let localPostionsEnd    = localPositions.count
            
            let isVertical = abs(fullDeltaY) > abs(fullDeltaX)
            mapLabelGpuMeta.append(MapLabelGpuMeta(
                measuredText: measuredText,
                scale: line.scale,
                locationStartIndex: simd_int1(localPostionsStart),
                locationEndIndex: simd_int1(localPostionsEnd),
                worldPathLen: line.pathLen,
                isVertical: isVertical,
                negativeDirection: isVertical ? (fullDeltaY < 0) : (fullDeltaX < 0)
            ))
            
            mapLabelCpuMeta.append(MapLabelCpuMeta(
                measuredText: measuredText,
                scale: line.scale,
                localPositions: line.localPositions,
                sortRank: line.sortRank,
                id: line.id,
                pathLen: line.pathLen,
                glyphShifts: glyphShifts
            ))
        }
        
        let verticesCount = vertices.count
        return DrawMapLabels(
            vertices: vertices,
            mapLabelSymbolMeta: mapLabelSymbolMeta,
            mapLabelGpuMeta: mapLabelGpuMeta,
            verticesCount: verticesCount,
            atlas: font.atlasTexture,
            mapLabelCpuMeta: mapLabelCpuMeta,
            localPositions: localPositions
        )
    }
    
    func assemble(lines: [TextLineData], font: Font) -> Result? {
        guard lines.isEmpty == false else { return nil }
        
        let arraysForGpu                = createArrays(lines: lines, font: font)
        let localPositions              = arraysForGpu.localPositions
        let vertices                    = arraysForGpu.vertices
        let mapLabelSymbolMeta          = arraysForGpu.mapLabelSymbolMeta
        let mapLabelGpuMeta             = arraysForGpu.mapLabelGpuMeta
        let verticesCount               = arraysForGpu.verticesCount
        let atlas                       = arraysForGpu.atlas
        let mapLabelCpuMeta             = arraysForGpu.mapLabelCpuMeta
        
        if verticesCount == 0 {
            return nil
        }
        
        let localPositionsBuffer        = metalDevice.makeBuffer(bytes: localPositions,
                                                                 length: MemoryLayout<LocalPosition>.stride * localPositions.count)!
            
        let vertexBuffer                = metalDevice.makeBuffer(bytes: vertices,
                                                                 length: MemoryLayout<TextVertex>.stride * verticesCount)!
        
        let mapLabelSymbolMetaBuffer    = metalDevice.makeBuffer(bytes: mapLabelSymbolMeta,
                                                                 length: MemoryLayout<MapLabelSymbolMeta>.stride * mapLabelSymbolMeta.count)!
        
        let mapLabelLineMetaBuffer      = metalDevice.makeBuffer(bytes: mapLabelGpuMeta,
                                                                 length: MemoryLayout<MapLabelGpuMeta>.stride * mapLabelGpuMeta.count)!
        
        
        var intersectionsTrippleBuffer      : [MTLBuffer] = []
        var startRoadAtTrippleBuffer        : [MTLBuffer] = []
        var lineToStartFloatsTrippleBuffer  : [MTLBuffer] = []
        
        for _ in 0..<3 {
            let intersectionsBuffer = metalDevice.makeBuffer(bytes: Array(repeating: LabelIntersection(hide: true, createdTime: 0), count: lines.count),
                                                             length: MemoryLayout<LabelIntersection>.stride * lines.count)!
            intersectionsTrippleBuffer.append(intersectionsBuffer)
            
            let startRoadAtBuffer = metalDevice.makeBuffer(bytes: Array(repeating: StartRoadAt(startAt: 0), count: lines.count),
                                                           length: MemoryLayout<StartRoadAt>.stride * lines.count)!
            startRoadAtTrippleBuffer.append(startRoadAtBuffer)
            
            let lineToStartFloatsBuffer = metalDevice.makeBuffer(bytes: Array(repeating: LineToStartAt(index: 0, count: 0), count: lines.count),
                                                                 length: MemoryLayout<LineToStartAt>.stride * lines.count)!
            lineToStartFloatsTrippleBuffer.append(lineToStartFloatsBuffer)
        }
        
        
        let drawData = MetalDrawMapLabels(vertexBuffer: vertexBuffer,
                                          mapLabelSymbolMeta: mapLabelSymbolMetaBuffer,
                                          mapLabelGpuMeta: mapLabelLineMetaBuffer,
                                          intersectionsTrippleBuffer: intersectionsTrippleBuffer,
                                          verticesCount: verticesCount,
                                          atlas: atlas,
                                          localPositionsBuffer: localPositionsBuffer,
                                          startRoadAtBuffer: startRoadAtTrippleBuffer,
                                          lineToStartFloatsBuffer: lineToStartFloatsTrippleBuffer)
        
        return Result(draw: drawData, mapLabelsCpuMeta: mapLabelCpuMeta)
    }
}
