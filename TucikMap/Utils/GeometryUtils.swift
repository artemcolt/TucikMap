//
//  GeometryUtils.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

class GeometryUtils {
    static func createCubeGeometryBuffers() -> ([SIMD3<Float>], [SIMD4<Float>]) {
        // Define a simple 3D geometry (cube vertices instead of triangle for 3D view)
        let positions: [SIMD3<Float>] = [
            // Front face
            SIMD3<Float>(-0.5, -0.5, 0.5),  // Bottom-left
            SIMD3<Float>(0.5, -0.5, 0.5),   // Bottom-right
            SIMD3<Float>(0.5, 0.5, 0.5),    // Top-right
            SIMD3<Float>(0.5, 0.5, 0.5),    // Top-right
            SIMD3<Float>(-0.5, 0.5, 0.5),   // Top-left
            SIMD3<Float>(-0.5, -0.5, 0.5),  // Bottom-left
            
            // Back face
            SIMD3<Float>(0.5, -0.5, -0.5),   // Bottom-right
            SIMD3<Float>(-0.5, -0.5, -0.5),  // Bottom-left
            SIMD3<Float>(-0.5, 0.5, -0.5),   // Top-left
            SIMD3<Float>(-0.5, 0.5, -0.5),   // Top-left
            SIMD3<Float>(0.5, 0.5, -0.5),    // Top-right
            SIMD3<Float>(0.5, -0.5, -0.5),   // Bottom-right
            
            // Left face
            SIMD3<Float>(-0.5, -0.5, -0.5),  // Bottom-left
            SIMD3<Float>(-0.5, -0.5, 0.5),   // Bottom-right
            SIMD3<Float>(-0.5, 0.5, 0.5),    // Top-right
            SIMD3<Float>(-0.5, 0.5, 0.5),    // Top-right
            SIMD3<Float>(-0.5, 0.5, -0.5),   // Top-left
            SIMD3<Float>(-0.5, -0.5, -0.5),  // Bottom-left
            
            // Right face
            SIMD3<Float>(0.5, -0.5, 0.5),    // Bottom-left
            SIMD3<Float>(0.5, -0.5, -0.5),   // Bottom-right
            SIMD3<Float>(0.5, 0.5, -0.5),    // Top-right
            SIMD3<Float>(0.5, 0.5, -0.5),    // Top-right
            SIMD3<Float>(0.5, 0.5, 0.5),     // Top-left
            SIMD3<Float>(0.5, -0.5, 0.5),    // Bottom-left
            
            // Top face
            SIMD3<Float>(-0.5, 0.5, 0.5),    // Bottom-left
            SIMD3<Float>(0.5, 0.5, 0.5),     // Bottom-right
            SIMD3<Float>(0.5, 0.5, -0.5),    // Top-right
            SIMD3<Float>(0.5, 0.5, -0.5),    // Top-right
            SIMD3<Float>(-0.5, 0.5, -0.5),   // Top-left
            SIMD3<Float>(-0.5, 0.5, 0.5),    // Bottom-left
            
            // Bottom face
            SIMD3<Float>(0.5, -0.5, 0.5),    // Bottom-left
            SIMD3<Float>(-0.5, -0.5, 0.5),   // Bottom-right
            SIMD3<Float>(-0.5, -0.5, -0.5),  // Top-right
            SIMD3<Float>(-0.5, -0.5, -0.5),  // Top-right
            SIMD3<Float>(0.5, -0.5, -0.5),   // Top-left
            SIMD3<Float>(0.5, -0.5, 0.5)     // Bottom-left
        ]
        
        // Colors for each vertex
        let colors: [SIMD4<Float>] = [
            // Front face - Red
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            
            // Back face - Green
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            
            // Left face - Blue
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            
            // Right face - Yellow
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
            
            // Top face - Magenta
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            
            // Bottom face - Cyan
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 1.0, 1.0)
        ]
        
        return (positions, colors)
    }
    
    
    static func createAxisGeometry(axisLength: Float, axisThickness: Float) -> ([SIMD3<Float>], [SIMD4<Float>]) {
        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        
        // Half-thickness for geometry calculations
        let t = axisThickness * 0.5
        
        // X-axis: Rectangular prism along X (red)
        let xVertices: [SIMD3<Float>] = [
            // Front face (z = -t)
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(axisLength, -t, -t), SIMD3<Float>(axisLength, t, -t),
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(axisLength, t, -t), SIMD3<Float>(0.0, t, -t),
            // Back face (z = t)
            SIMD3<Float>(0.0, -t, t), SIMD3<Float>(axisLength, -t, t), SIMD3<Float>(axisLength, t, t),
            SIMD3<Float>(0.0, -t, t), SIMD3<Float>(axisLength, t, t), SIMD3<Float>(0.0, t, t),
            // Top face (y = t)
            SIMD3<Float>(0.0, t, -t), SIMD3<Float>(axisLength, t, -t), SIMD3<Float>(axisLength, t, t),
            SIMD3<Float>(0.0, t, -t), SIMD3<Float>(axisLength, t, t), SIMD3<Float>(0.0, t, t),
            // Bottom face (y = -t)
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(axisLength, -t, -t), SIMD3<Float>(axisLength, -t, t),
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(axisLength, -t, t), SIMD3<Float>(0.0, -t, t),
            // Left face (x = 0)
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(0.0, t, -t), SIMD3<Float>(0.0, t, t),
            SIMD3<Float>(0.0, -t, -t), SIMD3<Float>(0.0, t, t), SIMD3<Float>(0.0, -t, t),
            // Right face (x = axisLength)
            SIMD3<Float>(axisLength, -t, -t), SIMD3<Float>(axisLength, t, -t), SIMD3<Float>(axisLength, t, t),
            SIMD3<Float>(axisLength, -t, -t), SIMD3<Float>(axisLength, t, t), SIMD3<Float>(axisLength, -t, t)
        ]
        let xColors = Array(repeating: SIMD4<Float>(1.0, 0.0, 0.0, 1.0), count: xVertices.count)
        
        // Y-axis: Rectangular prism along Y (green)
        let yVertices: [SIMD3<Float>] = [
            // Front face (z = -t)
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(t, 0.0, -t), SIMD3<Float>(t, axisLength, -t),
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(t, axisLength, -t), SIMD3<Float>(-t, axisLength, -t),
            // Back face (z = t)
            SIMD3<Float>(-t, 0.0, t), SIMD3<Float>(t, 0.0, t), SIMD3<Float>(t, axisLength, t),
            SIMD3<Float>(-t, 0.0, t), SIMD3<Float>(t, axisLength, t), SIMD3<Float>(-t, axisLength, t),
            // Right face (x = t)
            SIMD3<Float>(t, 0.0, -t), SIMD3<Float>(t, axisLength, -t), SIMD3<Float>(t, axisLength, t),
            SIMD3<Float>(t, 0.0, -t), SIMD3<Float>(t, axisLength, t), SIMD3<Float>(t, 0.0, t),
            // Left face (x = -t)
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(-t, axisLength, -t), SIMD3<Float>(-t, axisLength, t),
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(-t, axisLength, t), SIMD3<Float>(-t, 0.0, t),
            // Bottom face (y = 0)
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(t, 0.0, -t), SIMD3<Float>(t, 0.0, t),
            SIMD3<Float>(-t, 0.0, -t), SIMD3<Float>(t, 0.0, t), SIMD3<Float>(-t, 0.0, t),
            // Top face (y = axisLength)
            SIMD3<Float>(-t, axisLength, -t), SIMD3<Float>(t, axisLength, -t), SIMD3<Float>(t, axisLength, t),
            SIMD3<Float>(-t, axisLength, -t), SIMD3<Float>(t, axisLength, t), SIMD3<Float>(-t, axisLength, t)
        ]
        let yColors = Array(repeating: SIMD4<Float>(0.0, 1.0, 0.0, 1.0), count: yVertices.count)
        
        // Z-axis: Rectangular prism along Z (blue)
        let zVertices: [SIMD3<Float>] = [
            // Front face (y = -t)
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(t, -t, 0.0), SIMD3<Float>(t, -t, axisLength),
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(t, -t, axisLength), SIMD3<Float>(-t, -t, axisLength),
            // Back face (y = t)
            SIMD3<Float>(-t, t, 0.0), SIMD3<Float>(t, t, 0.0), SIMD3<Float>(t, t, axisLength),
            SIMD3<Float>(-t, t, 0.0), SIMD3<Float>(t, t, axisLength), SIMD3<Float>(-t, t, axisLength),
            // Right face (x = t)
            SIMD3<Float>(t, -t, 0.0), SIMD3<Float>(t, t, 0.0), SIMD3<Float>(t, t, axisLength),
            SIMD3<Float>(t, -t, 0.0), SIMD3<Float>(t, t, axisLength), SIMD3<Float>(t, -t, axisLength),
            // Left face (x = -t)
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(-t, t, 0.0), SIMD3<Float>(-t, t, axisLength),
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(-t, t, axisLength), SIMD3<Float>(-t, -t, axisLength),
            // Bottom face (z = 0)
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(t, -t, 0.0), SIMD3<Float>(t, t, 0.0),
            SIMD3<Float>(-t, -t, 0.0), SIMD3<Float>(t, t, 0.0), SIMD3<Float>(-t, t, 0.0),
            // Top face (z = axisLength)
            SIMD3<Float>(-t, -t, axisLength), SIMD3<Float>(t, -t, axisLength), SIMD3<Float>(t, t, axisLength),
            SIMD3<Float>(-t, -t, axisLength), SIMD3<Float>(t, t, axisLength), SIMD3<Float>(-t, t, axisLength)
        ]
        let zColors = Array(repeating: SIMD4<Float>(0.0, 0.0, 1.0, 1.0), count: zVertices.count)
        
        // Combine vertices and colors
        positions.append(contentsOf: xVertices)
        positions.append(contentsOf: yVertices)
        positions.append(contentsOf: zVertices)
        colors.append(contentsOf: xColors)
        colors.append(contentsOf: yColors)
        colors.append(contentsOf: zColors)
        
        return (positions, colors)
    }
}
