//
//  NeedComputeMapLabelsCollisions.swift
//  TucikMap
//
//  Created by Artem on 6/14/25.
//

class NeedComputeMapLabelsIntersections {
    private(set) var flag = false
    private(set) var instant = false
    
    private var textLabelsBatch: [MapLabelsMaker.TextLabelsFromTile] = []
    
    func labelsUpdated(textLabelsBatch: [MapLabelsMaker.TextLabelsFromTile]) {
        self.textLabelsBatch = textLabelsBatch
        setNeedsRecompute(instant: false)
    }
    
    func getCurrentLabels() -> [MapLabelsMaker.TextLabelsFromTile] {
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
