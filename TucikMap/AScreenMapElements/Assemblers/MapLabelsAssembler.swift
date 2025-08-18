//
//  MapLabelsAssembler.swift
//  TucikMap
//
//  Created by Artem on 6/10/25.
//
import MetalKit


class MapLabelsAssembler {
    struct MapLabelSymbolMeta {
        let lineMetaIndex: simd_int1
    }

    struct MapLabelCpuMeta {
        let measuredText    : MeasuredText
        let scale           : simd_float1
        let localPosition   : SIMD2<Float>
        let sortRank        : ushort
        let id              : UInt
    }

    struct MapLabelGpuMeta {
        let measuredText    : MeasuredText
        let scale           : simd_float1
        let localPosition   : SIMD2<Float>
    }
    
    struct MetalDrawMapLabels {
        let vertexBuffer                : MTLBuffer
        let mapLabelSymbolMeta          : MTLBuffer
        let mapLabelGpuMeta             : MTLBuffer
        var intersectionsTrippleBuffer  : [MTLBuffer]
        let verticesCount               : Int
        let atlas                       : MTLTexture
    }

    struct DrawMapLabels {
        let vertices                : [TextVertex]
        let mapLabelSymbolMeta      : [MapLabelSymbolMeta]
        let mapLabelGpuMeta         : [MapLabelGpuMeta]
        let verticesCount           : Int
        let atlas                   : MTLTexture
        let mapLabelCpuMeta         : [MapLabelCpuMeta]
    }
    
    struct Result {
        var metalDrawMapLabels      : MetalDrawMapLabels
        var mapLabelCpuMeta         : [MapLabelCpuMeta]
    }
    
    struct TextLineData {
        let text            : String
        let scale           : Float
        let localPosition   : SIMD2<Float>
        let id              : UInt
        let sortRank        : ushort
    }
    
    private let createTextGeometry  : CreateTextGeometry
    private let metalDevice         : MTLDevice
    private let frameCounter        : FrameCounter
    private let mapSettings         : MapSettings
    
    init(createTextGeometry: CreateTextGeometry, metalDevice: MTLDevice, frameCounter: FrameCounter, mapSettings: MapSettings) {
        self.createTextGeometry     = createTextGeometry
        self.metalDevice            = metalDevice
        self.frameCounter           = frameCounter
        self.mapSettings            = mapSettings
    }
    
    private func createArraysForGpu(lines: [TextLineData], font: Font) -> DrawMapLabels {
        var mapLabelSymbolMeta      : [MapLabelSymbolMeta] = []
        var mapLabelGpuMeta         : [MapLabelGpuMeta] = []
        var mapLabelCpuMeta         : [MapLabelCpuMeta] = []
        var vertices                : [TextVertex] = []
        
        for i in 0..<lines.count {
            func onGlyphCreated(scalar: Unicode.Scalar) {
                mapLabelSymbolMeta.append(MapLabelSymbolMeta(
                    lineMetaIndex: simd_int1(i)
                ))
            }
            
            let line            = lines[i]
            let text            = line.text
            let measuredText    = createTextGeometry.measureText(text: text, fontData: font.fontData)
            let textVertices    = createTextGeometry.create(text: text, fontData: font.fontData, onGlyphCreated: onGlyphCreated)
            vertices.append(contentsOf: textVertices)
            
            mapLabelGpuMeta.append(MapLabelGpuMeta(measuredText: measuredText,
                                                   scale: line.scale,
                                                   localPosition: line.localPosition))
            
            mapLabelCpuMeta.append(MapLabelCpuMeta(measuredText: measuredText,
                                                   scale: line.scale,
                                                   localPosition: line.localPosition,
                                                   sortRank: line.sortRank,
                                                   id: line.id))
        }
        
        let verticesCount = vertices.count
        return DrawMapLabels(vertices: vertices,
                             mapLabelSymbolMeta: mapLabelSymbolMeta,
                             mapLabelGpuMeta: mapLabelGpuMeta,
                             verticesCount: verticesCount,
                             atlas: font.atlasTexture,
                             mapLabelCpuMeta: mapLabelCpuMeta)
    }
    
    func assemble(lines: [TextLineData], font: Font) -> Result? {
        guard lines.isEmpty == false else { return nil }
        let assembledBytes  = createArraysForGpu(lines: lines, font: font)
        let mapLabelCpuMeta = assembledBytes.mapLabelCpuMeta
        
        let vertexBuffer                = metalDevice.makeBuffer(bytes: assembledBytes.vertices,
                                                                 length: MemoryLayout<TextVertex>.stride * assembledBytes.verticesCount)!
        
        let mapLabelSymbolMetaBuffer    = metalDevice.makeBuffer(bytes: assembledBytes.mapLabelSymbolMeta,
                                                                 length: MemoryLayout<MapLabelSymbolMeta>.stride * assembledBytes.mapLabelSymbolMeta.count)!
        
        let mapLabelGpuMetaBuffer       = metalDevice.makeBuffer(bytes: assembledBytes.mapLabelGpuMeta,
                                                                 length: MemoryLayout<MapLabelGpuMeta>.stride * assembledBytes.mapLabelGpuMeta.count)!
        
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        var intersectionsTrippleBuffer: [MTLBuffer] = []
        intersectionsTrippleBuffer.reserveCapacity(maxBuffersInFlight)
        for _ in 0..<maxBuffersInFlight {
            let intersectionsBuffer = metalDevice.makeBuffer(bytes: Array(repeating: LabelIntersection(hide: true, createdTime: 0), count: lines.count),
                                                             length: MemoryLayout<LabelIntersection>.stride * lines.count)!
            intersectionsTrippleBuffer.append(intersectionsBuffer)
        }
        
        let metalDrawMapLabels = MetalDrawMapLabels(
            vertexBuffer: vertexBuffer,
            mapLabelSymbolMeta: mapLabelSymbolMetaBuffer,
            mapLabelGpuMeta: mapLabelGpuMetaBuffer,
            intersectionsTrippleBuffer: intersectionsTrippleBuffer,
            verticesCount: assembledBytes.verticesCount,
            atlas: assembledBytes.atlas
        )
        return Result(metalDrawMapLabels: metalDrawMapLabels, mapLabelCpuMeta: mapLabelCpuMeta)
    }
}
