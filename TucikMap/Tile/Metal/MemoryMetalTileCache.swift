//
//  MetalTileCache.swift
//  TucikMap
//
//  Created by Artem on 6/7/25.
//

import MetalKit
import Foundation

class MemoryMetalTileCache {
    private struct CacheEntry {
        let tile: MetalTile
        let timestamp: Date
        let sizeInBytes: Int
    }
    
    private var cache: [String: CacheEntry] = [:]
    private let maxSizeBytes: Int
    private var currentSizeBytes: Int = 0
    
    // Максимальный размер кэша в байтах
    init(maxSizeBytes: Int) {
        self.maxSizeBytes = maxSizeBytes
    }
    
    // Добавление тайла в кэш
    func addTile(_ tile: MetalTile, forKey key: String) {
        // Рассчитываем размер буферов тайла в байтах
        let sizeInBytes = tile.verticesBuffer.allocatedSize +
                         tile.indicesBuffer.allocatedSize +
                         tile.stylesBuffer.allocatedSize +
                         tile.modelMatrixBuffer.allocatedSize
        
        // Создаем запись кэша
        let entry = CacheEntry(tile: tile, timestamp: Date(), sizeInBytes: sizeInBytes)
        
        // Добавляем в кэш
        cache[key] = entry
        currentSizeBytes += sizeInBytes
        
        // Очищаем кэш, если превышен максимальный размер
        cleanCacheIfNeeded()
    }
    
    // Получение тайла из кэша
    func getTile(forKey key: String) -> MetalTile? {
        
        if let entry = cache[key] {
            // Обновляем временную метку при доступе
            cache[key] = CacheEntry(tile: entry.tile, timestamp: Date(), sizeInBytes: entry.sizeInBytes)
            return entry.tile
        }
        return nil
    }
    
    // Удаление тайла из кэша
    func removeTile(forKey key: String) {
        if let entry = cache.removeValue(forKey: key) {
            currentSizeBytes -= entry.sizeInBytes
        }
    }
    
    // Очистка всего кэша
    func clearCache() {
        cache.removeAll()
        currentSizeBytes = 0
    }
    
    // Очистка кэша до допустимого размера
    private func cleanCacheIfNeeded() {
        while currentSizeBytes > maxSizeBytes, !cache.isEmpty {
            // Находим самый старый тайл
            if let oldestEntry = cache.min(by: { $0.value.timestamp < $1.value.timestamp }) {
                cache.removeValue(forKey: oldestEntry.key)
            }
        }
    }
    
    // Текущий размер кэша в МБ
    var currentSizeMB: Double {
        return Double(currentSizeBytes) / (1024 * 1024)
    }
}
