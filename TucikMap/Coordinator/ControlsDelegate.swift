//
//  ControlsDelegate.swift
//  TucikMap
//
//  Created by Artem on 5/31/25.
//

import SwiftUI

class ControlsDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow pinch and rotation to work together
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIPanGestureRecognizer {
            let panGesture = gestureRecognizer as? UIPanGestureRecognizer ?? otherGestureRecognizer as? UIPanGestureRecognizer
            if panGesture?.numberOfTouches == 2 {
                return true
            }
        }
            
        return false // Other combinations (e.g., pan and pinch) are exclusive
    }
}
