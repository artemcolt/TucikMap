//
//  NeedComputeMapLabelsCollisions.swift
//  TucikMap
//
//  Created by Artem on 6/14/25.
//

class NeedComputeMapLabelsIntersections {
    private(set) var flag = false
    private(set) var instant = false
    
    private var textLabelsBatch: [[ParsedTextLabel]] = []
    
    func labelsUpdated(textLabelsBatch: [[ParsedTextLabel]]) {
        self.textLabelsBatch = textLabelsBatch
        setNeedsRecompute(instant: false)
    }
    
    func getCurrentLabels() -> [[ParsedTextLabel]] {
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
