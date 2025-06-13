//
//  CreateTextGeometry.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

struct MeasuredText {
    let width: simd_float1
    let top: simd_float1
    let bottom: simd_float1
}

class CreateTextGeometry {
    func measureText(text: String, fontData: FontData) -> MeasuredText {
        var totalWidth: Float = 0
        var maxTop: Float = 0
        var maxBottom: Float = 0
        for char in text.unicodeScalars {
            let unicode = Int(char.value)
            if unicode == Settings.spaceUnicodeNumber { // space unicode
                totalWidth += Settings.spaceSize
            }
            if let glyph = fontData.glyphs.first(where: { $0.unicode == unicode }) {
                totalWidth += glyph.advance
                if let planeBounds = glyph.planeBounds {
                    if maxTop < planeBounds.top {
                        maxTop = planeBounds.top
                    }
                    if maxBottom > planeBounds.bottom {
                        maxBottom = planeBounds.bottom
                    }
                }
            }
        }
        return MeasuredText(width: totalWidth, top: maxTop, bottom: maxBottom)
    }
    
    func create(text: String, fontData: FontData, onGlyphCreated: ((_: Unicode.Scalar) -> Void)?) -> [TextVertex] {
        var vertices: [TextVertex] = []
        var shiftX: Float = 0
        
        for char in text.unicodeScalars {
            let unicode = Int(char.value)
            if unicode == Settings.spaceUnicodeNumber { // space unicode
                shiftX += Settings.spaceSize
            }
            if let glyph = fontData.glyphs.first(where: { $0.unicode == unicode }),
               let planeBounds = glyph.planeBounds,
               let atlasBounds = glyph.atlasBounds {
                
                // Координаты вершин для прямоугольника глифа
                let x = planeBounds.left + shiftX
                let y = planeBounds.bottom
                let w = planeBounds.right - planeBounds.left
                let h = planeBounds.top - planeBounds.bottom
                
                // Текстурные координаты из атласа
                let texLeft = atlasBounds.left / fontData.atlas.width
                let texRight = atlasBounds.right / fontData.atlas.width
                let texTop = atlasBounds.top / fontData.atlas.height
                let texBottom = atlasBounds.bottom / fontData.atlas.height
                
                // Добавление вершин для двух треугольников (прямоугольник)
                vertices.append(TextVertex(position: vector_float2(x, y), texCoord: vector_float2(texLeft, 1.0 - texBottom)))
                vertices.append(TextVertex(position: vector_float2(x + w, y), texCoord: vector_float2(texRight, 1.0 - texBottom)))
                vertices.append(TextVertex(position: vector_float2(x, y + h), texCoord: vector_float2(texLeft, 1.0 - texTop)))
                
                vertices.append(TextVertex(position: vector_float2(x + w, y), texCoord: vector_float2(texRight, 1.0 - texBottom)))
                vertices.append(TextVertex(position: vector_float2(x + w, y + h), texCoord: vector_float2(texRight, 1.0 - texTop)))
                vertices.append(TextVertex(position: vector_float2(x, y + h), texCoord: vector_float2(texLeft, 1.0 - texTop)))
                
                onGlyphCreated?(char)
                shiftX += glyph.advance
            }
        }
        
        return vertices
    }
}
