//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

class ScreenCollisionsDetector {
    private let computeLabelScreen: ComputeLabelScreen
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    
    private let uniformBuffer: MTLBuffer
    private let inputModelMatricesBuffer: MTLBuffer
    private let inputScreenPositionsBuffer: MTLBuffer
    private let outputWorldPositionsBuffer: MTLBuffer
    private let inputBufferWorldPostionsSize = 1500
    private let modelMatrixBufferSize = 15
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState
    ) {
        computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        
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
    
    func evaluateTilesData(tiles: [MetalTile], lastUniforms: Uniforms, mapPanning: SIMD3<Double>) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var copyToUniform = lastUniforms
        
        var inputComputeScreenVertices: [InputComputeScreenVertex] = []
        var modelMatrices = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        var metaLines: [MapLabelLineMeta] = []
        var labelsTileStartIndices: [Int] = []
        for i in 0..<tiles.count {
            let tile = tiles[i]
            let tileModelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            modelMatrices[i] = tileModelMatrix
            
            labelsTileStartIndices.append(-1)
            guard let textLabels = tile.textLabels else { continue }
            let inputArray = textLabels.metaLines.map { label in InputComputeScreenVertex(location: label.localPosition, matrixId: simd_short1(i)) }
            inputComputeScreenVertices.append(contentsOf: inputArray)
            labelsTileStartIndices[labelsTileStartIndices.count - 1] = metaLines.count
            metaLines.append(contentsOf: textLabels.metaLines)
        }
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
            let output = computeScreenPositions.readOutput()
            let timeSpentInNanoseconds = buffer.gpuEndTime - buffer.gpuStartTime
            let timeSpentInSeconds = Double(timeSpentInNanoseconds) / 1_000_000_000.0
            
            
            let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
            var labelIntersections = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: output.count)
            for i in 0..<output.count {
                let screenPositions = output[i]
                let metaLine = metaLines[i]
                let added = spaceDiscretisation.addAgent(agent: CollisionAgent2(
                    location: SIMD2<Float>(Float(screenPositions.x + 5000), Float(screenPositions.y + 5000)),
                    height: Float((abs(metaLine.measuredText.top) + abs(metaLine.measuredText.bottom)) * metaLine.scale),
                    width: Float(metaLine.measuredText.width * metaLine.scale)
                ))
                labelIntersections[i] = LabelIntersection(hide: added == false, createdTime: 0)
            }
            
            var startIndex = 0
            for i in 0..<tiles.count {
                let tile = tiles[i]
                guard let textLabels = tile.textLabels else { continue }
                let count = textLabels.metaLines.count
                let subArray = Array(labelIntersections[startIndex ..< startIndex + count])
                
                tile.textLabels?.drawMapLabelsData.intersectionsBuffer
                    .contents()
                    .copyMemory(from: subArray, byteCount: MemoryLayout<LabelIntersection>.stride * subArray.count)
                
                startIndex += count
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let absoluteTimeSpent = endTime - startTime
            print("timeSpent = \(absoluteTimeSpent)")
            //print("positions = ", spaceDiscretisation.positions)
        }
        commandBuffer.commit()
    }
}
