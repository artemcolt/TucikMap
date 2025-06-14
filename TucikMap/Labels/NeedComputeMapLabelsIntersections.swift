//
//  NeedComputeMapLabelsCollisions.swift
//  TucikMap
//
//  Created by Artem on 6/14/25.
//

class NeedComputeMapLabelsIntersections {
    private(set) var flag = false
    private(set) var instant = false
    private var result: MapLabelsAssembler.Result? = nil
 
    func labelsUpdated(result: MapLabelsAssembler.Result) {
        self.result = result
        setNeedsRecompute(instant: false)
    }
    
    func getLablesResult() -> MapLabelsAssembler.Result? {
        return result
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
