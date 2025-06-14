//
//  FrameCounter.swift
//  TucikMap
//
//  Created by Artem on 5/30/25.
//

import Foundation
import Metal

class FrameCounter {
    private let startTime = CFAbsoluteTimeGetCurrent()
    private var lastFrameTime: CFAbsoluteTime
    private var frameCount: Int
    private var deltaTime: Double
    private var frameCountCallback: ((Int) -> Void)?
    
    // Инициализатор
    init() {
        self.lastFrameTime = CFAbsoluteTimeGetCurrent()
        self.frameCount = 0
        self.deltaTime = 0.0
    }
    
    // Установить callback для количества кадров
    func onFrameCount(_ callback: @escaping (Int) -> Void) {
        self.frameCountCallback = callback
    }
    
    func getElapsedTimeSeconds() -> Float {
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        return Float(elapsedTime)
    }
    
    // Вызывается каждый кадр, принимает commandBuffer для отслеживания времени выполнения
    func update(with commandBuffer: MTLCommandBuffer) {
        frameCount += 1
        
        // Добавляем обработчик завершения для commandBuffer
        commandBuffer.addCompletedHandler { [weak self] buffer in
            guard let self = self else { return }
            
            // Получаем время начала и окончания выполнения команд
            let startTime = buffer.gpuStartTime
            let endTime = buffer.gpuEndTime
            
            // Вычисляем delta time на основе времени GPU
            if startTime > 0 && endTime > 0 {
                self.deltaTime = endTime - startTime
            } else {
                // Fallback на CPU-время, если GPU-время недоступно
                let currentTime = CFAbsoluteTimeGetCurrent()
                self.deltaTime = currentTime - self.lastFrameTime
                self.lastFrameTime = currentTime
            }
            
            // Вызываем callback для количества кадров, если он установлен
            if let frameCallback = self.frameCountCallback {
                frameCallback(self.frameCount)
            }
        }
    }
    
    // Получить текущее значение delta time
    func getDeltaTime() -> Double {
        return deltaTime
    }
    
    // Получить текущее количество кадров
    func getFrameCount() -> Int {
        return frameCount
    }
    
    // Сбросить счетчик
    func reset() {
        lastFrameTime = CFAbsoluteTimeGetCurrent()
        frameCount = 0
        deltaTime = 0.0
    }
}
