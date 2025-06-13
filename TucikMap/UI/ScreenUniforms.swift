//
//  ScreenUniforms.swift
//  TucikMap
//
//  Created by Artem on 6/13/25.
//

import SwiftUI
import Foundation
import MetalKit

class ScreenUniforms {
    let metalDevice: MTLDevice
    private(set) var viewportSize: SIMD2<Float>!
    private(set) var screenUniformBuffer: MTLBuffer!
    
    func update(size: CGSize) {
        viewportSize = SIMD2<Float>(Float(size.width), Float(size.height))
        updateMatrix(size: size)
    }
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
    }
    
    private func updateMatrix(size: CGSize) {
        let projectionMatrix = MatrixUtils.orthographicMatrix(left: 0, right: Float(size.width), bottom: 0, top: Float(size.height), near: -1, far: 1.0)
        var uniforms = Uniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: matrix_identity_float4x4,
            viewportSize: SIMD2<Float>(Float(size.width), Float(size.height))
        )
            
        screenUniformBuffer = metalDevice.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: .storageModeShared
        )!
    }
}
