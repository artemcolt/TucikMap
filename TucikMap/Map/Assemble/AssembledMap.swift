//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//


struct AssembledMap {
    var parsedTiles: [ParsedTile]
    var allStyles: [UInt8]
    
    static func void() -> AssembledMap {
        return AssembledMap(parsedTiles: [], allStyles: [])
    }
}
