//
//  MapCADisplayLoop.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

class MapCADisplayLoop {
    private let mapLablesIntersection: MapLabelsIntersection
    private let updateBufferedUniform: UpdateBufferedUniform
    private let needComputeMapLabelsIntersections: NeedComputeMapLabelsIntersections
    
    private var loopCount: UInt64 = 0
    
    private var computeIntersectionsEvery: UInt64 = Settings.refreshLabelsIntersectionsEveryNDisplayLoop
    
    init(mapLablesIntersection: MapLabelsIntersection,
         updateBufferedUniform: UpdateBufferedUniform,
         needComputeMapLabelsIntersections: NeedComputeMapLabelsIntersections
    ) {
        self.mapLablesIntersection = mapLablesIntersection
        self.updateBufferedUniform = updateBufferedUniform
        self.needComputeMapLabelsIntersections = needComputeMapLabelsIntersections
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (canComputeIntersectionsNow()) {
            guard let lastUniforms = updateBufferedUniform.lastUniforms,
                  let labelsAssembled = needComputeMapLabelsIntersections.getLablesResult() else { return }
            mapLablesIntersection.computeIntersections(MapLabelsIntersection.FindIntersections(
                labelsAssembled: labelsAssembled,
                uniforms: lastUniforms
            ))
        }
    }
    
    private func canComputeIntersectionsNow() -> Bool {
        let isComputeNeeded = needComputeMapLabelsIntersections.flag
        let instant = needComputeMapLabelsIntersections.instant
        if loopCount % computeIntersectionsEvery == 0 && isComputeNeeded || instant {
            needComputeMapLabelsIntersections.called()
            return true
        }
        return false
    }
}
