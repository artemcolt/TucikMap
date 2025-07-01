//
//  GiveMeMapId.swift
//  TucikMap
//
//  Created by Artem on 6/16/25.
//

class GiveMeId {
    private var textLabelsCurrent: UInt = 0
    
    func forScreenCollisionsDetection() -> UInt {
        textLabelsCurrent += 1
        return textLabelsCurrent
    }
}
