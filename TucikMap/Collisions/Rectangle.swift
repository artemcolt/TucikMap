//
//  Rectangle.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

struct Rectangle {
    var topLeft: SIMD2<Float>
    var bottomRight: SIMD2<Float>
    
    // Initialize with topLeft and bottomRight points
    init(topLeft: SIMD2<Float>, bottomRight: SIMD2<Float>) {
        self.topLeft = topLeft
        self.bottomRight = bottomRight
    }
    
    // Check if the rectangle is valid (topLeft is above and to the left of bottomRight)
    var isValid: Bool {
        return topLeft.x <= bottomRight.x && topLeft.y >= bottomRight.y
    }
    
    // Check if this rectangle intersects with another
    func intersection(with other: Rectangle) -> Bool {
        // Check if both rectangles are valid
        guard isValid && other.isValid else { return false }
        
        // Check if rectangles intersect
        let xLeft = max(topLeft.x, other.topLeft.x)
        let xRight = min(bottomRight.x, other.bottomRight.x)
        let yTop = min(topLeft.y, other.topLeft.y)
        let yBottom = max(bottomRight.y, other.bottomRight.y)
        
        return xLeft <= xRight && yBottom <= yTop
    }
}
