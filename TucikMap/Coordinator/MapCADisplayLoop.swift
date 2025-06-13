//
//  MapCADisplayLoop.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

class MapCADisplayLoop {
    private let mapLablesIntersection: MapLabelsIntersection
    private let assembledMap: AssembledMap
    private var loopCount: UInt64 = 0
    
    init(mapLablesIntersection: MapLabelsIntersection, assembledMap: AssembledMap) {
        self.mapLablesIntersection = mapLablesIntersection
        self.assembledMap = assembledMap
    }
    
    func displayLoop() {
        loopCount += 1
        print("loop count: \(loopCount)")
    }
}
