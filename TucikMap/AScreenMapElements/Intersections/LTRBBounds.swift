//
//  LTRBBounds.swift
//  TucikMap
//
//  Created by Artem on 8/13/25.
//

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
    
    static func from(location: SIMD2<Float>, height: Float, width: Float) -> LTRBBounds {
        let halfW1 = width / 2
        let halfH1 = height / 2
        let l1 = location.x - halfW1
        let r1 = location.x + halfW1
        let b1 = location.y - halfH1
        let t1 = location.y + halfH1
        return LTRBBounds(l: l1, t: t1, r: r1, b: b1)
    }
}

extension LTRBBounds: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(l)
        hasher.combine(t)
        hasher.combine(r)
        hasher.combine(b)
    }
}
