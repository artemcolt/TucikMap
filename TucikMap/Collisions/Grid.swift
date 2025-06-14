//
//  Grid.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//


struct SectorIndex: Hashable {
    let row: Int
    let col: Int
}

class Grid {
    let width: Float
    let height: Float
    let horizontalDivisions: Int
    let verticalDivisions: Int
    private let cellWidth: Float
    private let cellHeight: Float
    private var sectors: [[[Int]]]
    private var rectangles: [Rectangle] = []
    
    // Initialize grid with dimensions and number of divisions
    init(width: Float, height: Float, horizontalDivisions: Int, verticalDivisions: Int) {
        self.width = width
        self.height = height
        self.horizontalDivisions = max(1, horizontalDivisions)
        self.verticalDivisions = max(1, verticalDivisions)
        self.cellWidth = width / Float(horizontalDivisions)
        self.cellHeight = height / Float(verticalDivisions)
        // Initialize sectors array: [row][col] contains array of Rectangle indices
        self.sectors = Array(repeating: Array(repeating: [], count: horizontalDivisions), count: verticalDivisions)
    }
    
    // Calculate sector index from a point
    private func sectorIndex(for point: SIMD2<Float>) -> SectorIndex? {
        // Ensure point is within grid bounds
        guard point.x >= 0, point.x <= width, point.y >= 0, point.y <= height else {
            return nil
        }
        
        // Calculate column and row indices (y=0 at bottom)
        let col = min(Int(point.x / cellWidth), horizontalDivisions - 1)
        let row = min(Int(point.y / cellHeight), verticalDivisions - 1)
        
        return SectorIndex(row: row, col: col)
    }
    
    // Insert a Rectangle and add its index to the sectors it occupies
    func insertAndCheckIntersection(rectangle: Rectangle) -> Bool? {
        // Check if rectangle is valid
        guard rectangle.isValid else {
            return nil
        }
        
        // Get sector indices for topLeft and bottomRight
        guard let topLeftSector = sectorIndex(for: rectangle.topLeft),
              let bottomRightSector = sectorIndex(for: rectangle.bottomRight) else {
            return nil
        }
        
        // Iterate over all sectors and check intersections
        for row in min(topLeftSector.row, bottomRightSector.row)...max(topLeftSector.row, bottomRightSector.row) {
            for col in min(topLeftSector.col, bottomRightSector.col)...max(topLeftSector.col, bottomRightSector.col) {
                let sector = sectors[row][col]
                for rectangleIndex in sector {
                    let otherRect = rectangles[rectangleIndex]
                    let intersect = rectangle.intersection(with: otherRect)
                    if intersect {  return true }
                }
            }
        }
        
        for row in min(topLeftSector.row, bottomRightSector.row)...max(topLeftSector.row, bottomRightSector.row) {
            for col in min(topLeftSector.col, bottomRightSector.col)...max(topLeftSector.col, bottomRightSector.col) {
                // Add rectangle index to the sector
                sectors[row][col].append(rectangles.count)
                rectangles.append(rectangle)
            }
        }
        
        return false
    }
    
    // Get all Rectangle indices in a given sector
    func rectangles(inSector sector: SectorIndex) -> [Int] {
        guard sector.row >= 0, sector.row < verticalDivisions,
              sector.col >= 0, sector.col < horizontalDivisions else {
            return []
        }
        return sectors[sector.row][sector.col]
    }
}
