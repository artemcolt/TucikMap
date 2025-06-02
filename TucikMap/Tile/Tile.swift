//
//  Tile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

// Структура для представления тайла
struct Tile {
    let x: Int
    let y: Int
    let z: Int
    
    init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}
