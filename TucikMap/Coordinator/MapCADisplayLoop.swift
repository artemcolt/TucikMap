//
//  MapCADisplayLoop.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

class MapCADisplayLoop {
    private let mapLabelsMaker: MapLabelsMaker
    private let needComputeMapLabelsIntersections: NeedComputeMapLabelsIntersections
    private let camera: Camera
    private let frameCounter: FrameCounter
    
    private var loopCount: UInt64 = 0
    private var computeIntersectionsEvery: UInt64 = Settings.refreshLabelsIntersectionsEveryNDisplayLoop
    
    init(mapLabelsMaker: MapLabelsMaker,
         needComputeMapLabelsIntersections: NeedComputeMapLabelsIntersections,
         camera: Camera,
         frameCounter: FrameCounter
    ) {
        self.camera = camera
        self.frameCounter = frameCounter
        self.mapLabelsMaker = mapLabelsMaker
        self.needComputeMapLabelsIntersections = needComputeMapLabelsIntersections
    }
    
    func displayLoop() {
        loopCount += 1
        
        if (canComputeIntersectionsNow()) {
            let newLabels = needComputeMapLabelsIntersections.getNewLabels()
            let makeLabels = MapLabelsMaker.MakeLabels(
                newLabels: newLabels,
                currentElapsedTime: frameCounter.getElapsedTimeSeconds(),
                mapPanning: camera.mapPanning,
                lastUniforms: camera.updateBufferedUniform.lastUniforms,
                viewportSize: camera.updateBufferedUniform.lastViewportSize
            )
            mapLabelsMaker.queueLabelsUpdating(makeLabels)
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
