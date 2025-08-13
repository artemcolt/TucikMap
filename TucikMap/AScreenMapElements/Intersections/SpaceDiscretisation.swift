//
//  LocalClustering.swift
//  TucikMap
//
//  Created by Artem on 7/1/25.
//

import Foundation

//public class SpaceDiscretisation : SpaceIntersectionsProtocol {
//    var positions: [(Int, Int, Int, Int)] = []
//    
//    let clusterSize: Float
//    let count: Int
//    public var clusters: [[LTRBBounds?]] = [[]]
//    
//    public init(clusterSize: Float, count: Int) {
//        self.clusterSize = clusterSize
//        self.count = count
//        
//        clusters = Array(repeating: Array(repeating: nil, count: count), count: count)
//    }
//    
//    func add(bounds: LTRBBounds) -> Bool {
//        let positionXLeft = max(min(Int(floor(bounds.l / clusterSize)), count - 1), 0)
//        let positionXRight = max(min(Int(floor(bounds.r / clusterSize)), count - 1), 0)
//        let positionYBottom = max(min(Int(floor(bounds.b / clusterSize)), count - 1), 0)
//        let positionYTop = max(min(Int(floor(bounds.t / clusterSize)), count - 1), 0)
//        
//        for x in positionXLeft...positionXRight {
//            for y in positionYBottom...positionYTop {
//                guard let compareWith = clusters[x][y] else { continue }
//                if compareWith.intersects(with: bounds) {
//                    return false
//                }
//            }
//        }
//        
//        for x in positionXLeft...positionXRight {
//            for y in positionYBottom...positionYTop {
//                clusters[x][y] = bounds
//            }
//        }
//        
//        return true
//    }
//    
//    public func addAsSingle(bounds: [LTRBBounds]) -> Bool {
//        for bound in bounds {
//            
//            let positionXLeft = max(min(Int(floor(bound.l / clusterSize)), count - 1), 0)
//            let positionXRight = max(min(Int(floor(bound.r / clusterSize)), count - 1), 0)
//            let positionYBottom = max(min(Int(floor(bound.b / clusterSize)), count - 1), 0)
//            let positionYTop = max(min(Int(floor(bound.t / clusterSize)), count - 1), 0)
//            
//            for x in positionXLeft...positionXRight {
//                for y in positionYBottom...positionYTop {
//                    guard let compareWith = clusters[x][y] else { continue }
//                    if compareWith.intersects(with: bound) {
//                        return false
//                    }
//                }
//            }
//        }
//        
//        for bound in bounds {
//            
//            let positionXLeft = max(min(Int(floor(bound.l / clusterSize)), count - 1), 0)
//            let positionXRight = max(min(Int(floor(bound.r / clusterSize)), count - 1), 0)
//            let positionYBottom = max(min(Int(floor(bound.b / clusterSize)), count - 1), 0)
//            let positionYTop = max(min(Int(floor(bound.t / clusterSize)), count - 1), 0)
//            
//            for x in positionXLeft...positionXRight {
//                for y in positionYBottom...positionYTop {
//                    clusters[x][y] = bound
//                }
//            }
//        }
//        
//        return true
//    }
//}
