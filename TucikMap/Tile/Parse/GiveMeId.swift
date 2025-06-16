//
//  GiveMeMapId.swift
//  TucikMap
//
//  Created by Artem on 6/16/25.
//

class GiveMeId {
    private var textLabelsCurrent: UInt64 = 0
    
    func forTextLabel() -> UInt64 {
        textLabelsCurrent += 1
        return textLabelsCurrent
    }
}
