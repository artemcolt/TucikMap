//
//  GiveMeMapId.swift
//  TucikMap
//
//  Created by Artem on 6/16/25.
//

actor GiveMeId {
    private var textLabelsCurrent: UInt = 0
    private var ids: [UniqueGeoLabelKey:UInt] = [:]
    
    func getIdForLabel(uniqueGeoLabelKey: UniqueGeoLabelKey) -> UInt {
        if let dedicated = ids[uniqueGeoLabelKey] {
            return dedicated
        }
        
        textLabelsCurrent += 1
        ids[uniqueGeoLabelKey] = textLabelsCurrent
        return textLabelsCurrent
    }
    
    private var idForRoadLabelIncrement: UInt = 0
    
    func getIdForRoadLabel() -> UInt {
        idForRoadLabelIncrement += 1
        return idForRoadLabelIncrement
    }
}
