//
//  TucikMapTests.swift
//  TucikMapTests
//
//  Created by Artem on 7/1/25.
//

import Foundation
import Testing
import TucikMap

struct TucikMapTests {
    func randomFloat(in range: ClosedRange<Float>) -> Float {
        return Float.random(in: range)
    }
    
//    @Test func intersections() throws {
//        
//        let startTime = CFAbsoluteTimeGetCurrent()
//        let tightGrid = TightGrid(height: 600, width: 600, cellSize: 60, reserveAgentNodes: 400_000)
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(100, 100), height: 10, width: 10, id: 0))
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(94, 94), height: 10, width: 10, id: 1))
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(0, 0), height: 10, width: 10, id: 2))
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(200, 200), height: 10, width: 10, id: 3))
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(0, 200), height: 10, width: 10, id: 4))
////        tightGrid.addAgent(agent: CollisionAgent(location: SIMD2<Float16>(100, 100), height: 10, width: 10, id: 5))
//        for i in 0..<3_000 {
//            let location = SIMD2<Float16>(randomFloat16(in: 0...600), randomFloat16(in: 0...600))
//            tightGrid.addAgent(agent: CollisionAgent(location: location, height: 15, width: 40, id: i))
//        }
//        
//        let intersections = tightGrid.findIntersections()
//        print(intersections)
//        
//        let endTime = CFAbsoluteTimeGetCurrent()
//        let delta = endTime - startTime
//        print("time = ", delta)
//        
//        //try #require(intersections.count == 1)
//    }
    
    @Test func clusterFixed() {
        
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 30, count: 10)
        let added1 = spaceDiscretisation.addAgent(agent: CollisionAgent2(location: SIMD2<Float>(0, 0), height: 15, width: 50))
        let added2 = spaceDiscretisation.addAgent(agent: CollisionAgent2(location: SIMD2<Float>(50, 0), height: 15, width: 100))
        let added3 = spaceDiscretisation.addAgent(agent: CollisionAgent2(location: SIMD2<Float>(200, 0), height: 15, width: 50))
    }
    
    @Test func cluster() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var addedCount = 0
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 30, count: 400)
        for i in 0..<10_000 {
            let location = SIMD2<Float>(randomFloat(in: 0...10_000), randomFloat(in: 0...10_000))
            let added1 = spaceDiscretisation.addAgent(agent: CollisionAgent2(location: location, height: 15, width: 50))
            if added1 {
                addedCount += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let delta = endTime - startTime
        print("time = ", delta, " added = ", addedCount)
    }
}
