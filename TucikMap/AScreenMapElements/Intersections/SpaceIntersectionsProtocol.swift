//
//  SpaceIntersectionsProtocol.swift
//  TucikMap
//
//  Created by Artem on 8/13/25.
//

protocol SpaceIntersectionsProtocol {
    func add(shape: Shape) -> Bool
    func addAsSingle(shapes: [Shape]) -> Bool
}
