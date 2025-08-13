//
//  SpaceIntersections.swift
//  TucikMap
//
//  Created by Artem on 8/13/25.
//

import Foundation

// Define Circle
public struct Circle {
    var centerX: Float
    var centerY: Float
    var radius: Float
}

// Enum for shapes
public enum Shape: Hashable {
    case rect(LTRBBounds)
    case circle(Circle)
    
    // Get bounding box for the shape
    func boundingBox() -> LTRBBounds {
        switch self {
        case .rect(let bounds):
            return bounds
        case .circle(let circle):
            return LTRBBounds(
                l: circle.centerX - circle.radius,
                t: circle.centerY + circle.radius,
                r: circle.centerX + circle.radius,
                b: circle.centerY - circle.radius
            )
        }
    }
    
    // Intersects method
    func intersects(with other: Shape) -> Bool {
        switch (self, other) {
        case (.rect(let r1), .rect(let r2)):
            return r1.intersects(with: r2)
        case (.circle(let c1), .circle(let c2)):
            let dx = c1.centerX - c2.centerX
            let dy = c1.centerY - c2.centerY
            let distance = sqrt(dx * dx + dy * dy)
            return distance <= (c1.radius + c2.radius)
        case (.rect(let rect), .circle(let circle)):
            return rectIntersectsCircle(rect: rect, circle: circle)
        case (.circle(let circle), .rect(let rect)):
            return rectIntersectsCircle(rect: rect, circle: circle)
        }
    }
    
    // Helper for rect-circle intersection
    private func rectIntersectsCircle(rect: LTRBBounds, circle: Circle) -> Bool {
        // Find the closest point on the rect to the circle center
        let closestX = max(rect.l, min(circle.centerX, rect.r))
        let closestY = max(rect.b, min(circle.centerY, rect.t))
        
        // Distance from closest point to circle center
        let dx = closestX - circle.centerX
        let dy = closestY - circle.centerY
        let distance = sqrt(dx * dx + dy * dy)
        
        // Intersects if distance <= radius (includes touching)
        return distance <= circle.radius
    }
}

// Make Circle Hashable
extension Circle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(centerX)
        hasher.combine(centerY)
        hasher.combine(radius)
    }
}

// Cell identifier for the grid
struct Cell: Hashable {
    let x: Int
    let y: Int
}

class SpaceIntersections: SpaceIntersectionsProtocol {
    private var grid: [Cell: [Shape]] = [:]
    private let cellSize: Float = 200.0  // Chosen to create about 100x100 cells for -10000 to 10000 range
    private let minCoord: Float = -10000.0
    private let maxCoord: Float = 10000.0
    
    // Helper to get all cells a shape overlaps (via its bounding box)
    private func getCells(for shape: Shape) -> [Cell] {
        let bounds = shape.boundingBox()
        // Clamp to overall space if needed, but assuming bounds are within -10000 to 10000
        let minX = Int(floor(bounds.l / cellSize))
        let maxX = Int(floor(bounds.r / cellSize))
        let minY = Int(floor(bounds.b / cellSize))
        let maxY = Int(floor(bounds.t / cellSize))
        
        var cells: [Cell] = []
        for x in minX...maxX {
            for y in minY...maxY {
                cells.append(Cell(x: x, y: y))
            }
        }
        return cells
    }
    
    func add(shape: Shape) -> Bool {
        // First, find all cells the new shape would occupy
        let candidateCells = getCells(for: shape)
        
        // Collect unique candidate shapes that might intersect
        var candidates: Set<Shape> = []
        for cell in candidateCells {
            if let cellShapes = grid[cell] {
                for s in cellShapes {
                    candidates.insert(s)
                }
            }
        }
        
        // Check if the new shape intersects with any candidate
        for existing in candidates {
            if shape.intersects(with: existing) {
                return false  // Intersection found, discard
            }
        }
        
        // No intersections, add to the grid
        for cell in candidateCells {
            grid[cell, default: []].append(shape)
        }
        return true
    }
    
    func addAsSingle(shapes: [Shape]) -> Bool {
        // First, collect all cells that any shape in the group would occupy
        var allCandidateCells: Set<Cell> = []
        for shape in shapes {
            let cells = getCells(for: shape)
            allCandidateCells.formUnion(cells)
        }
        
        // Collect unique candidate existing shapes from those cells
        var candidates: Set<Shape> = []
        for cell in allCandidateCells {
            if let cellShapes = grid[cell] {
                for s in cellShapes {
                    candidates.insert(s)
                }
            }
        }
        
        // Check if any shape in the group intersects with any candidate
        for shape in shapes {
            for existing in candidates {
                if shape.intersects(with: existing) {
                    return false  // Intersection found, discard entire group
                }
            }
        }
        
        // No intersections, add all shapes to the grid
        for shape in shapes {
            let cells = getCells(for: shape)
            for cell in cells {
                grid[cell, default: []].append(shape)
            }
        }
        return true
    }
}
