//
//  AssembledMap.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

struct AssembledMap {
    var polygonFeatures: [AssembledMapFeature]
    
    static func void() -> AssembledMap {
        return AssembledMap(polygonFeatures: [])
    }
}
