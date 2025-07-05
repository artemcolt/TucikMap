//
//  GiveMeMapId.swift
//  TucikMap
//
//  Created by Artem on 6/16/25.
//

actor GiveMeId {
    private var textLabelsCurrent: UInt = 0
    private var ids: [UniqueGeoLabelKey:UInt] = [:]
    
    func forScreenCollisionsDetection(uniqueGeoLabelKey: UniqueGeoLabelKey) -> UInt {
        if let dedicated = ids[uniqueGeoLabelKey] {
            return dedicated
        }
        
        textLabelsCurrent += 1
        ids[uniqueGeoLabelKey] = textLabelsCurrent
        return textLabelsCurrent
    }
}
