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
    
    // Проверяет, покрывает ли текущий тайл другой тайл
    func covers(_ other: Tile) -> Bool {
        // Тайл покрывает другой, если он имеет меньший уровень зума
        // и содержит координаты другого тайла
        if z >= other.z {
            return false
        }
        
        // Вычисляем масштаб между уровнями зума
        let scale = 1 << (other.z - z)
        
        // Проверяем, попадают ли координаты другого тайла в область текущего
        let minX = x * scale
        let maxX = (x + 1) * scale - 1
        let minY = y * scale
        let maxY = (y + 1) * scale - 1
        
        return other.x >= minX && other.x <= maxX &&
               other.y >= minY && other.y <= maxY
    }
}
