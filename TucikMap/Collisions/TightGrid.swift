//
//  TightGrid.swift
//  TucikMap
//
//  Created by Artem on 7/1/25.
//

import Foundation

public struct CollisionAgent {
    public let id: Int
    public let bounds: LTRBBounds
    
    public init(location: SIMD2<Float16>, height: Float16, width: Float16, id: Int) {
        let halfW1 = width / 2
        let halfH1 = height / 2
        let l1 = location.x - halfW1
        let r1 = location.x + halfW1
        let b1 = location.y - halfH1
        let t1 = location.y + halfH1
        bounds = LTRBBounds(l: l1, t: t1, r: r1, b: b1)
        self.id = id
    }
}

public struct LTRBBounds {
    var l, t, r, b: Float16 // AABB extents relative to grid origin
    
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

public class TightGrid {
    let height: Float16
    let width: Float16
    let cellSize: Float16
    let numCols: Int
    let numRows: Int
    
    public struct Cell {
        public var head: Int // head to agent node
    }
    
    public struct AgentNode {
        public var agentIdx: Int
        public var next: Int
    }
    
    public var agents: [CollisionAgent] = []
    public var agentNodes: [AgentNode]
    public var cells: [Cell]
    
    var freeAgentNode = 0
    
    public init(height: Float16, width: Float16, cellSize: Float16, reserveAgentNodes: Int) {
        self.height = height
        self.width = width
        self.cellSize = cellSize
        
        numCols = Int(floor(width / cellSize))
        numRows = Int(floor(height / cellSize))
        
        agentNodes = (0..<reserveAgentNodes).map { AgentNode(agentIdx: -1, next: $0 < reserveAgentNodes - 1 ? $0 + 1 : -1) }
        freeAgentNode = 0
        
        cells = Array(repeating: Cell(head: -1), count: numCols * numRows)
    }
    
    public func addAgent(agent: CollisionAgent) {
        let agentIdx = agents.count
        agents.append(agent)
        
        let bounds = agent.bounds
        let leftTop = SIMD2<Float16>(bounds.l, bounds.t)
        let leftBottom = SIMD2<Float16>(bounds.l, bounds.b)
        let rightTop = SIMD2<Float16>(bounds.r, bounds.t)
        let rightBottom = SIMD2<Float16>(bounds.r, bounds.b)
        
        let cellIdx1 = addAgentTo(agentIdx: agentIdx, point: leftTop, exceptCellIdx: [])
        let cellIdx2 = addAgentTo(agentIdx: agentIdx, point: leftBottom, exceptCellIdx: [cellIdx1])
        let cellIdx3 = addAgentTo(agentIdx: agentIdx, point: rightTop, exceptCellIdx: [cellIdx1, cellIdx2])
        _ = addAgentTo(agentIdx: agentIdx, point: rightBottom, exceptCellIdx: [cellIdx1, cellIdx2, cellIdx3])
    }
    
    public func findIntersections2() -> [(Int, Int)] {
        var intersections: [(Int, Int)] = []
        var ignoreAgent: Set<Int> = []
        
        for cell in cells {
            if cell.head == -1 { continue }
            
            var agentNodeIdx = cell.head
            while agentNodeIdx != -1 {
                let agentNode = agentNodes[agentNodeIdx]
                let agent = agents[agentNode.agentIdx]
                if ignoreAgent.contains(agent.id) { continue }
                agentNodeIdx = agentNode.next
                
                var agentNodeIdxNext = agentNode.next
                while agentNodeIdxNext != -1 {
                    let agentNodeNext = agentNodes[agentNodeIdxNext]
                    let nextAgent = agents[agentNodeNext.agentIdx]
                    if ignoreAgent.contains(nextAgent.id) { continue }
                    agentNodeIdxNext = agentNodeNext.next
                    
                    if agent.bounds.intersects(with: nextAgent.bounds) {
                        intersections.append((agent.id, nextAgent.id))
                        let maxId = min(agent.id, nextAgent.id)
                        ignoreAgent.insert(maxId)
                    }
                }
            }
        }
        
        return intersections
    }
    
    public func findIntersections() -> [(Int, Int)] {
        var intersections: [(Int, Int)] = []
        var agentIndex = 0
        var agentSplitBlocks: [Int] = []
        var allignedAgents: [CollisionAgent?] = Array(repeating: nil, count: agentNodes.count)
        for cell in cells {
            var agentNodeIdx = cell.head
            while agentNodeIdx != -1 {
                let agentNode = agentNodes[agentNodeIdx]
                agentNodeIdx = agentNode.next
                allignedAgents[agentIndex] = agents[agentNode.agentIdx]
                agentIndex += 1
            }
            agentSplitBlocks.append(agentIndex)
        }
        
        var ignoreAgent: Set<Int> = []
        for i in 0..<agentSplitBlocks.count {
            let next = agentSplitBlocks[i]
            let previous = i > 0 ? agentSplitBlocks[i-1] : 0
            
            for i2 in previous..<next-1 {
                let agent = allignedAgents[i2]!
                if ignoreAgent.contains(agent.id) { continue }
                
                for i3 in i2+1..<next {
                    let otherAgent = allignedAgents[i3]!
                    if ignoreAgent.contains(otherAgent.id) { continue }
                    
                    let intersect = agent.bounds.intersects(with: otherAgent.bounds)
                    if intersect {
                        intersections.append((agent.id, otherAgent.id))
                        let maxId = min(agent.id, otherAgent.id)
                        ignoreAgent.insert(maxId)
                    }
                }
            }
        }
        
        return intersections
    }
    
    private func addAgentTo(agentIdx: Int, point: SIMD2<Float16>, exceptCellIdx: [Int]) -> Int {
        let cellX = min(max(Int(floor(point.x / cellSize)), 0), numCols-1)
        let cellY = min(max(Int(floor(point.y / cellSize)), 0), numRows-1)
        
        let cellIdx = cellY * numCols + cellX
        if exceptCellIdx.contains(cellIdx) {
            return -1
        }
        let cell = cells[cellIdx]
        let agentNode = AgentNode(agentIdx: agentIdx, next: cell.head)
        
        if freeAgentNode != -1 {
            let nextFreeNode = agentNodes[freeAgentNode].next
            agentNodes[freeAgentNode] = agentNode
            cells[cellIdx].head = freeAgentNode
            freeAgentNode = nextFreeNode
        }
        
        return cellIdx
    }
}
