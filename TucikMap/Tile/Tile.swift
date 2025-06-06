//
//  Tile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

// Структура для представления тайла
import MetalKit
import Foundation

struct Tile {
    let x: Int
    let y: Int
    let z: Int
    
    func key() -> String {
        return "\(z)_\(x)_\(y)"
    }
    
    init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}
