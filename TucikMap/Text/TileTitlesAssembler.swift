//
//  TitlesTextGeometry.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import Foundation
import MetalKit

class TileTitlesAssembler {
    private let textAssembler: TextAssembler
    
    init(textAssembler: TextAssembler) {
        self.textAssembler = textAssembler
    }
    
    func assemble(tiles: [Tile], font: Font, scale: Float, offset: SIMD2<Float>) -> DrawTextData {
        let mapSize = Settings.mapSize
        var texts: [TextAssembler.TextLineData] = []
        for tile in tiles {
            let zoomFactor = pow(2.0, Float(tile.z))
            let lastTileCoord = Int(zoomFactor) - 1
            let tileSize = mapSize / zoomFactor
            let offsetX = Float(tile.x) * tileSize - mapSize / 2.0
            let offsetY = Float(lastTileCoord - tile.y) * tileSize - mapSize / 2.0
            let text = "x:\(tile.x) y:\(tile.y) z:\(tile.z)"
            
            texts.append(TextAssembler.TextLineData(
                text: text,
                offset: SIMD3<Float>(offsetX + offset.x, offsetY + offset.y, 0),
                rotation: SIMD3<Float>(0, 0, 0),
                scale: scale
            ))
        }
        
        return textAssembler.assemble(lines: texts, font: font)
    }
}
