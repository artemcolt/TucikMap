//
//  TileMapAssembler.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class TileMapAssembler {
    func assemble(parsedTiles: [ParsedTile]) -> AssembledMap {
        let allStyles = Array(Set(parsedTiles.flatMap { $0.styles.keys }))
        return AssembledMap(parsedTiles: parsedTiles, allStyles: allStyles)
    }
}
