//
//  Tile.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

// Структура для представления тайла
import MetalKit
import Foundation

struct MapPanningTilePoint {
    let x: Double
    let y: Double
}

// Сделал чтобы определять одинаковые надписи на карте при переходе между тайлами
// Москва на уровне зума 7 далее 8 далее 9 и тд
// это нужно для правильной анимации затухания
// Только вот логика опредления выглядит относительно дорогой
// надо будет может подумать и может есть какой-то более дешевый вариант
// просто проверять по строке нельзя так как существуют например села с одинаковыми названиями и они достаточно близко
// либо это данные такие грязные с несколькими метками с одинаковыми именами населенных пунктов в пределах достижимой видимости
// возможно надо просто настроить стили для отображения названий населенных пунктов
// Показывать меньше маленьких и незначимых населенных пунктов при маленьких зумах чтобы они не дублировались
// Этот класс определяет уникальность и по близости друг к другу и по имени населенного пункта
struct UniqueGeoLabelKey : Hashable {
    let x: Double
    let y: Double
    let name: String
    let hashPrecision: Double = 1_000_0
    
    func hash(into hasher: inout Hasher) {
        // Округляем координаты до заданной точности
        let roundedX = (x * hashPrecision).rounded()
        let roundedY = (y * hashPrecision).rounded()
        hasher.combine(roundedX)
        hasher.combine(roundedY)
        hasher.combine(name)
    }
    
    static func == (lhs: UniqueGeoLabelKey, rhs: UniqueGeoLabelKey) -> Bool {
        // Сравниваем с той же точностью, что и в hash(into:)
        let precision = lhs.hashPrecision
        let roundedX1 = (lhs.x * precision).rounded()
        let roundedY1 = (lhs.y * precision).rounded()
        let roundedX2 = (rhs.x * precision).rounded()
        let roundedY2 = (rhs.y * precision).rounded()
        return roundedX1 == roundedX2 && roundedY1 == roundedY2 && lhs.name == rhs.name
    }
}

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
    
    func findParentTile(atZoom targetZoom: Int) -> Tile? {
        // Проверяем, что текущий зум больше целевого (иначе родителя нет на targetZoom)
        guard z >= targetZoom, targetZoom >= 0 else {
            return nil
        }
        
        // Разница в уровнях зума
        let zoomDifference = z - targetZoom
        
        // Вычисляем координаты родительского тайла
        // Делим x и y на 2^(разница зумов), берём целую часть
        let parentX = x >> zoomDifference
        let parentY = y >> zoomDifference
        
        return Tile(x: parentX, y: parentY, z: targetZoom)
    }
    
    func getTilePointPanningCoordinates(normalizedX: Double, normalizedY: Double) -> MapPanningTilePoint {
        // Размер тайла на зуме 0
        let mapSize = Double(Settings.mapSize)
        
        // Размер тайла на текущем зуме: mapSize / 2^z
        let tileSize = mapSize / pow(2.0, Double(z))
        let halfTileSize = tileSize / 2
        
        // Глобальные координаты:
        // Базовая позиция тайла + локальная координата, масштабированная на размер тайла
        let globalX = (Double(x) * tileSize + halfTileSize + normalizedX * halfTileSize) - mapSize / 2
        let globalY = (Double(y) * tileSize + halfTileSize - normalizedY * halfTileSize) - mapSize / 2
        
        return MapPanningTilePoint(x: -globalX, y: globalY)
    }
}
