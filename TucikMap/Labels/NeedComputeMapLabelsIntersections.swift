//
//  NeedComputeMapLabelsCollisions.swift
//  TucikMap
//
//  Created by Artem on 6/14/25.
//

class NeedComputeMapLabelsIntersections {
    private(set) var flag = false
    private(set) var instant = false
    
    private var alreadyGaveNewLabels: Bool = false
    private var textLabelsBatch: [MapLabelsMaker.TextLabelsFromTile] = []
    
    func labelsUpdated(textLabelsBatch: [MapLabelsMaker.TextLabelsFromTile]) {
        self.textLabelsBatch = textLabelsBatch
        setNeedsRecompute(instant: false)
        alreadyGaveNewLabels = false
    }
    
    func getNewLabels() -> [MapLabelsMaker.TextLabelsFromTile]? {
        if alreadyGaveNewLabels == true {
            return nil
        }
        
        alreadyGaveNewLabels = true
        return textLabelsBatch
    }
    
    func setNeedsRecompute(instant: Bool = false) {
        self.instant = instant
        flag = true
    }
    
    func called() {
        flag = false
        instant = false
    }
}
