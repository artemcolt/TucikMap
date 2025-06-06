//
//  Debouncer.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import Foundation

class Debouncer<T> {
    private var items: [T] = []
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let debounceInterval: TimeInterval
    private let processHandler: ([T]) -> Void
    
    /// Инициализатор
    /// - Parameters:
    ///   - debounceInterval: Задержка перед обработкой (в секундах)
    ///   - queue: Очередь для выполнения обработки (по умолчанию .userInitiated)
    ///   - processHandler: Замыкание для обработки массива элементов
    init(
        debounceInterval: TimeInterval = 0.5,
        queue: DispatchQueue = .init(label: "com.debouncer.generic", qos: .userInitiated),
        processHandler: @escaping ([T]) -> Void
    ) {
        self.debounceInterval = debounceInterval
        self.queue = queue
        self.processHandler = processHandler
    }
    
    /// Добавляет элемент для обработки
    /// - Parameter item: Элемент типа T
    func addItem(_ item: T) {
        queue.async { [weak self] in
            guard let self else { return }
            
            // Добавляем элемент
            self.items.append(item)
            
            // Отменяем предыдущую задачу
            self.workItem?.cancel()
            
            // Создаем новую задачу
            let newWorkItem = DispatchWorkItem { [weak self] in
                self?.processItems()
            }
            
            self.workItem = newWorkItem
            self.queue.asyncAfter(deadline: .now() + self.debounceInterval, execute: newWorkItem)
        }
    }
    
    /// Обрабатывает накопленные элементы
    private func processItems() {
        queue.async { [weak self] in
            guard let self, !self.items.isEmpty else { return }
            
            // Вызываем пользовательский обработчик
            self.processHandler(self.items)
            
            // Очищаем массив
            self.items.removeAll()
        }
    }
}
