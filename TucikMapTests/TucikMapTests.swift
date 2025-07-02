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
    
    @Test func clusterFixed() {
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 30, count: 10)
        let added1 = spaceDiscretisation.addAgent(agent: CollisionAgent(location: SIMD2<Float>(0, 0), height: 15, width: 50))
        let added2 = spaceDiscretisation.addAgent(agent: CollisionAgent(location: SIMD2<Float>(50, 0), height: 15, width: 100))
        let added3 = spaceDiscretisation.addAgent(agent: CollisionAgent(location: SIMD2<Float>(200, 0), height: 15, width: 50))
    }
    
    @Test func cluster() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var addedCount = 0
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 30, count: 400)
        for i in 0..<10_000 {
            let location = SIMD2<Float>(randomFloat(in: 0...10_000), randomFloat(in: 0...10_000))
            let added1 = spaceDiscretisation.addAgent(agent: CollisionAgent(location: location, height: 15, width: 50))
            if added1 {
                addedCount += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let delta = endTime - startTime
        print("time = ", delta, " added = ", addedCount)
    }
}
