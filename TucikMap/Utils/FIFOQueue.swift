//
//  FIFOQueue.swift
//  TucikMap
//
//  Created by Artem on 6/5/25.
//

class FIFOQueue<T> {
    private var elements: [T?]
    private var head: Int = 0
    private var tail: Int = 0
    private var capacity: Int
    private var size: Int = 0
    
    // Инициализация с заданной емкостью
    init(capacity: Int) {
        self.capacity = max(1, capacity) // Минимальная емкость 1
        self.elements = [T?](repeating: nil, count: capacity)
    }
    
    // Добавление элемента в конец очереди
    @discardableResult
    func enqueue(_ element: T) -> Bool {
        guard size < capacity else { return false } // Проверка на переполнение
        elements[tail] = element
        tail = (tail + 1) % capacity
        size += 1
        return true
    }
    
    // Удаление и возврат первого элемента
    func dequeue() -> T? {
        guard size > 0 else { return nil } // Проверка на пустую очередь
        let element = elements[head]
        elements[head] = nil
        head = (head + 1) % capacity
        size -= 1
        return element
    }
    
    // Получение первого элемента без удаления
    var front: T? {
        return size > 0 ? elements[head] : nil
    }
    
    // Проверка, пуста ли очередь
    var isEmpty: Bool {
        return size == 0
    }
    
    // Проверка, заполнена ли очередь
    var isFull: Bool {
        return size == capacity
    }
    
    // Текущее количество элементов
    var count: Int {
        return size
    }
    
    // Очистка очереди
    func clear() {
        elements = [T?](repeating: nil, count: capacity)
        head = 0
        tail = 0
        size = 0
    }
}
