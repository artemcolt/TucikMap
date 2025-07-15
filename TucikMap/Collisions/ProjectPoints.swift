//
//  ProjectPoints.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit

class ProjectPoints {
    struct ProjectInput {
        let modelMatrices: [matrix_float4x4]
        let uniforms: Uniforms
        let mapPanning: SIMD3<Double>
        let inputComputeScreenVertices: [InputComputeScreenVertex]
        
        let metalGeoLabels: [MetalGeoLabels]
        let mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta]
        let actualLabelsIds: Set<UInt>
        let geoLabelsSize: Int
        
        let nextResultsIndex: Int
        let roadLabels: [MetalRoadLabels]
    }
    
    struct Result {
        let input: ProjectInput
        let output: [SIMD2<Float>]
    }
    
    private let computeLabelScreen: ComputeLabelScreen
    private let metalCommandQueue: MTLCommandQueue
    
    private let uniformBuffer: MTLBuffer
    private let inputModelMatricesBuffer: MTLBuffer
    private let inputScreenPositionsBuffer: MTLBuffer
    private let outputWorldPositionsBuffer: MTLBuffer
    private let inputBufferWorldPostionsSize = 1500
    private let modelMatrixBufferSize = 60
    private let onPointsReady: (Result) -> Void
    
    init(
        computeLabelScreen: ComputeLabelScreen,
        metalDevice: MTLDevice,
        metalCommandQueue: MTLCommandQueue,
        onPointsReady: @escaping (Result) -> Void
    ) {
        self.onPointsReady = onPointsReady
        self.computeLabelScreen = computeLabelScreen
        self.metalCommandQueue = metalCommandQueue
        
        var inputScreenPositionsMock = Array(
            repeating: InputComputeScreenVertex(location: SIMD2<Float>(), matrixId: 0),
            count: inputBufferWorldPostionsSize
        )
        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<Uniforms>.stride)!
        inputScreenPositionsBuffer = metalDevice.makeBuffer(
            bytes: &inputScreenPositionsMock,
            length: MemoryLayout<InputComputeScreenVertex>.stride * inputBufferWorldPostionsSize
        )!
        var inputModelMatrices = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        inputModelMatricesBuffer = metalDevice.makeBuffer(
            bytes: &inputModelMatrices,
            length: MemoryLayout<matrix_float4x4>.stride * modelMatrixBufferSize
        )!
        outputWorldPositionsBuffer = metalDevice.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * inputBufferWorldPostionsSize)!
    }
    
    func project(input: ProjectInput) {
        // проецируем из мировых координат в координаты экрана
        // для этого нужен тайл чтобы матрицу трансформации сделать в мировые координаты из локальных координат тайла
        var modelMatrices = input.modelMatrices
        var copyToUniform = input.uniforms
        var inputComputeScreenVertices = input.inputComputeScreenVertices
        
        // для вызова заполянем текущие буффера в GPU
        inputModelMatricesBuffer.contents().copyMemory(
            from: &modelMatrices,
            byteCount: MemoryLayout<matrix_float4x4>.stride * modelMatrices.count
        )
        uniformBuffer.contents().copyMemory(from: &copyToUniform, byteCount: MemoryLayout<Uniforms>.stride)
        inputScreenPositionsBuffer.contents().copyMemory(
            from: &inputComputeScreenVertices, byteCount: MemoryLayout<InputComputeScreenVertex>.stride * inputComputeScreenVertices.count
        )
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        let computeScreenPositions = ComputeScreenPositions(
            inputModelMatricesBuffer: inputModelMatricesBuffer,
            inputBuffer: inputScreenPositionsBuffer,
            outputBuffer: outputWorldPositionsBuffer,
            vertexCount: inputBufferWorldPostionsSize,
            readVerticesCount: inputComputeScreenVertices.count
        )
        
        computeLabelScreen.compute(
            uniforms: uniformBuffer,
            computeEncoder: computeCommandEncoder,
            computeScreenPositions: computeScreenPositions
        )
        
        computeCommandEncoder.endEncoding()
        commandBuffer.addCompletedHandler { buffer in
            // Вычислили экранные координаты на gpu
            let output = computeScreenPositions.readOutput()
            self.onPointsReady(Result(input: input, output: output))
        }
        commandBuffer.commit()
    }
}
