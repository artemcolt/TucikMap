//
//  CameraUI.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit

class CameraUI {
    private let device: MTLDevice
    private var projectionMatrix: matrix_float4x4!
    private(set) var uniformsBuffer: MTLBuffer!
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func updateMatrix(size: CGSize) {
        projectionMatrix = MatrixUtils.orthographicMatrix(left: 0, right: Float(size.width), bottom: 0, top: Float(size.height), near: -1, far: 1.0)
        var uniforms = Uniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: matrix_identity_float4x4
        )
            
        uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: .storageModeShared
        )!
    }
}
