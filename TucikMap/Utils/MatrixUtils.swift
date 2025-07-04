// MatrixUtils.swift
//
// Utility functions for 3D matrix operations

import simd

struct MatrixUtils {
    static func orthographicMatrix(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4 {
        let rml = right - left
        let tmb = top - bottom
        let fmn = far - near
        
        return matrix_float4x4(
            SIMD4<Float>(2.0 / rml, 0.0, 0.0, 0.0),
            SIMD4<Float>(0.0, 2.0 / tmb, 0.0, 0.0),
            SIMD4<Float>(0.0, 0.0, -2.0 / fmn, 0.0),
            SIMD4<Float>(-(right + left) / rml, -(top + bottom) / tmb, -(far + near) / fmn, 1.0)
        )
    }
    
    static func perspectiveMatrix(fovRadians: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        return matrix_float4x4(
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
    }
    
    static func createTileModelMatrix(scaleX: Float, scaleY: Float, scaleZ: Float,
                                      offsetX: Float, offsetY: Float) -> matrix_float4x4 {
        // Матрица масштабирования
        let scaleMatrix = matrix_float4x4(
            SIMD4<Float>(scaleX, 0,      0, 0),
            SIMD4<Float>(0,      scaleY, 0, 0),
            SIMD4<Float>(0,      0,      scaleZ, 0),
            SIMD4<Float>(0,      0,      0, 1)
        )
        
        // Матрица смещения
        let translationMatrix = matrix_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(offsetX, offsetY, 0, 1)
        )
        
        // Комбинируем: сначала масштабирование, затем смещение
        return translationMatrix * scaleMatrix
    }
    
    // Create a translation matrix
    static func translationMatrix(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix[3][0] = x
        matrix[3][1] = y
        matrix[3][2] = z
        return matrix
    }
    
    // Create a rotation matrix around the x-axis
    static func rotationMatrixX(radians: Float) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix[1][1] = cos(radians)
        matrix[1][2] = sin(radians)
        matrix[2][1] = -sin(radians)
        matrix[2][2] = cos(radians)
        return matrix
    }
    
    // Create a rotation matrix around the y-axis
    static func rotationMatrixY(radians: Float) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix[0][0] = cos(radians)
        matrix[0][2] = -sin(radians)
        matrix[2][0] = sin(radians)
        matrix[2][2] = cos(radians)
        return matrix
    }
    
    // Create a rotation matrix around the z-axis
    static func rotationMatrixZ(radians: Float) -> matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix[0][0] = cos(radians)
        matrix[0][1] = sin(radians)
        matrix[1][0] = -sin(radians)
        matrix[1][1] = cos(radians)
        return matrix
    }
    
    // Create a look-at view matrix
    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let f = normalize(center - eye)
        let s = normalize(cross(f, up))
        let u = cross(s, f)
        
        return matrix_float4x4(
            SIMD4<Float>(s.x, u.x, -f.x, 0),
            SIMD4<Float>(s.y, u.y, -f.y, 0),
            SIMD4<Float>(s.z, u.z, -f.z, 0),
            SIMD4<Float>(-dot(s, eye), -dot(u, eye), dot(f, eye), 1)
        )
    }
}
