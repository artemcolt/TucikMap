//
//  TextAssembler.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class TextAssembler {
    private let createTextGeometry: CreateTextGeometry
    private let metalDevice: MTLDevice
    
    init(createTextGeometry: CreateTextGeometry, metalDevice: MTLDevice) {
        self.createTextGeometry = createTextGeometry
        self.metalDevice = metalDevice
    }
    
    struct TextLineData {
        let text: String
        let offset: SIMD3<Float>
        let rotation: SIMD3<Float>
        let scale: Float
    }
    
    func assembleBytes(lines: [TextLineData], font: Font) -> DrawTextDataBytes {
        var glyphProps: [GlyphGpuProp] = []
        var vertices: [TextVertex] = []
        
        for line in lines {
            let text = line.text
            let vertex = createTextGeometry.create(text: text, fontData: font.fontData, onGlyphCreated: { scalar in
                glyphProps.append(GlyphGpuProp(
                    translation: line.offset,
                    rotation: line.rotation,
                    scale: line.scale
                ))
            })
            vertices.append(contentsOf: vertex)
        }
        
        let verticesCount = vertices.count
        
        return DrawTextDataBytes(
            vertices: vertices,
            glyphProps: glyphProps,
            verticesCount: verticesCount,
            atlas: font.atlasTexture
        )
    }
    
    func assemble(lines: [TextLineData], font: Font) -> DrawTextData {
        let assembledBytes = assembleBytes(lines: lines, font: font)
        
        let vertexBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.vertices,
            length: MemoryLayout<TextVertex>.stride * assembledBytes.verticesCount,
            options: .storageModeShared
        )!
        let glyphBuffer = metalDevice.makeBuffer(
            bytes: assembledBytes.glyphProps,
            length: MemoryLayout<GlyphGpuProp>.stride * assembledBytes.glyphProps.count,
            options: .storageModeShared
        )!
        return DrawTextData(
            vertexBuffer: vertexBuffer,
            glyphPropBuffer: glyphBuffer,
            verticesCount: assembledBytes.verticesCount,
            atlas: assembledBytes.atlas
        )
    }
}
