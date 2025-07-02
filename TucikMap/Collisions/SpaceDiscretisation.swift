//
//  LocalClustering.swift
//  TucikMap
//
//  Created by Artem on 7/1/25.
//

import Foundation

public struct CollisionAgent {
    public let bounds: LTRBBounds
    
    public init(location: SIMD2<Float>, height: Float, width: Float) {
        let halfW1 = width / 2
        let halfH1 = height / 2
        let l1 = location.x - halfW1
        let r1 = location.x + halfW1
        let b1 = location.y - halfH1
        let t1 = location.y + halfH1
        bounds = LTRBBounds(l: l1, t: t1, r: r1, b: b1)
    }
}

public struct LTRBBounds {
    var l, t, r, b: Float // AABB extents relative to grid origin
    
    // Checks if this bounds intersects with another LTRBBounds
    func intersects(with other: LTRBBounds) -> Bool {
        // No intersection if one box is to the left or right of the other
        if self.r < other.l || other.r < self.l {
            return false
        }
        
        // No intersection if one box is above or below the other
        if self.t < other.b || other.t < self.b {
            return false
        }
        
        // If neither of the above conditions are true, the boxes intersect
        return true
    }
}

public class SpaceDiscretisation {
    var positions: [(Int, Int, Int, Int)] = []
    
    let clusterSize: Float
    let count: Int
    public var clusters: [[CollisionAgent?]] = [[]]
    
    public init(clusterSize: Float, count: Int) {
        self.clusterSize = clusterSize
        self.count = count
        
        clusters = Array(repeating: Array(repeating: nil, count: count), count: count)
    }
    
    public func addAgent(agent: CollisionAgent) -> Bool {
        let bounds = agent.bounds
        
        let positionXLeft = max(min(Int(floor(bounds.l / clusterSize)), count - 1), 0)
        let positionXRight = max(min(Int(floor(bounds.r / clusterSize)), count - 1), 0)
        let positionYBottom = max(min(Int(floor(bounds.b / clusterSize)), count - 1), 0)
        let positionYTop = max(min(Int(floor(bounds.t / clusterSize)), count - 1), 0)
        
        for x in positionXLeft...positionXRight {
            for y in positionYBottom...positionYTop {
                guard let compareWith = clusters[x][y] else { continue }
                if compareWith.bounds.intersects(with: bounds) {
                    return false
                }
            }
        }
        
        for x in positionXLeft...positionXRight {
            for y in positionYBottom...positionYTop {
                clusters[x][y] = agent
            }
        }
        
        return true
    }
}
