//
//  ApplyLabelsState.swift
//  TucikMap
//
//  Created by Artem on 7/16/25.
//

class ApplyLabelsState {
    private let screenCollisionsDetector: ScreenCollisionsDetector
    private var assembledMap: AssembledMap
    
    init(screenCollisionsDetector: ScreenCollisionsDetector, assembledMap: AssembledMap) {
        self.screenCollisionsDetector = screenCollisionsDetector
        self.assembledMap = assembledMap
    }
    
    func apply(
        currentFBIdx: Int
    ) {
        // Применяем новую информацию о метках
        // Когда мы уже посчитали коллизии и все что нужно для отрисвки
        // дорожные метки и просто метки
        
        if let labelsWithIntersections = screenCollisionsDetector.getLabelsWithIntersections() {
            let geoLabels               = labelsWithIntersections.geoLabels
            assembledMap.tileGeoLabels  = geoLabels
            let intersections           = labelsWithIntersections.intersections
            
            for i in 0..<assembledMap.tileGeoLabels.count {
                guard let intersections     = intersections[i] else { continue }
                let tileGeoLabels           = geoLabels[i]
                guard let textLabels        = tileGeoLabels.textLabels else { continue }
                let buffer                  = textLabels.metalDrawMapLabels.intersectionsTrippleBuffer[currentFBIdx]
                
                buffer.contents().copyMemory(from: intersections, byteCount: MemoryLayout<LabelIntersection>.stride * intersections.count)
            }
        }
        
        
        if let roadLabelsTB = screenCollisionsDetector.getRoadLabels() {
            var finalRoadLabels       : [DrawAssembledMap.FinalDrawRoadLabel] = []
            let tilesPrepare          = roadLabelsTB.tilesPrepare
            
            for i in 0..<tilesPrepare.count {
                let tileRoadLabels      = tilesPrepare[i]
                let lineToStartAt       = tileRoadLabels.lineToStartAt
                let startAt             = tileRoadLabels.startAt
                let metalRoadLabels     = tileRoadLabels.metalRoadLabels
                
                guard let roadLabels    = metalRoadLabels.roadLabels else { continue }
                let draw                = roadLabels.draw
                
                draw.lineToStartFloatsBuffer[currentFBIdx].contents().copyMemory(from: lineToStartAt,
                                                                                 byteCount: MemoryLayout<MapRoadLabelsAssembler.LineToStartAt>.stride * lineToStartAt.count)
                
                draw.startRoadAtBuffer[currentFBIdx].contents().copyMemory(from: startAt,
                                                                           byteCount: MemoryLayout<MapRoadLabelsAssembler.StartRoadAt>.stride * startAt.count)
                
                finalRoadLabels.append(DrawAssembledMap.FinalDrawRoadLabel(metalRoadLabels: tileRoadLabels.metalRoadLabels,
                                                                           maxInstances: tileRoadLabels.maxInstances))
            }
            
            assembledMap.roadLabels = finalRoadLabels
        }
    }
}
