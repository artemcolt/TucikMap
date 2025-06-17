//
//  NeedComputeMapLabelsCollisions.swift
//  TucikMap
//
//  Created by Artem on 6/14/25.
//

class NeedComputeMapLabelsIntersections {
    private(set) var flag = false
    private(set) var instant = false
    
    private var textLabelsBatch: [MapLabelsIntersection.TextLabelsFromTile] = []
    
    func labelsUpdated(textLabelsBatch: [MapLabelsIntersection.TextLabelsFromTile]) {
        self.textLabelsBatch = textLabelsBatch
        setNeedsRecompute(instant: false)
    }
    
    func getCurrentLabels() -> [MapLabelsIntersection.TextLabelsFromTile] {
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
