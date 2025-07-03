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
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    
    private let uniformBuffer: MTLBuffer
    private let inputModelMatricesBuffer: MTLBuffer
    private let inputScreenPositionsBuffer: MTLBuffer
    private let outputWorldPositionsBuffer: MTLBuffer
    private let inputBufferWorldPostionsSize = 1500
    private let modelMatrixBufferSize = 15
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    
    // the most possible actual intersections data
    private var newDataFlag: Int = Settings.maxBuffersInFlight
    private var intersectionsResultByTiles: [Int: [LabelIntersection]] = [:]
    
    func getIntersectionsByTiles() -> [Int: [LabelIntersection]]? {
        if newDataFlag <= 0 { return nil }
        
        newDataFlag -= 1
        return intersectionsResultByTiles
    }
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        
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
        var labelIds: [UInt] = []
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
            labelIds.append(contentsOf: tile.textLabelsIds)
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
            _ = Double(timeSpentInNanoseconds) / 1_000_000_000.0
            
            let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
            var labelIntersections = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: output.count)
            for i in 0..<output.count {
                let screenPositions = output[i]
                let metaLine = metaLines[i]
                let collisionId = labelIds[i]
                let added = spaceDiscretisation.addAgent(agent: CollisionAgent(
                    location: SIMD2<Float>(Float(screenPositions.x + 5000), Float(screenPositions.y + 5000)),
                    height: Float((abs(metaLine.measuredText.top) + abs(metaLine.measuredText.bottom)) * metaLine.scale),
                    width: Float(metaLine.measuredText.width * metaLine.scale)
                ))
                
                let hide = added == false
                let previousState = self.savedLabelIntersections[collisionId]
                let previousStateIsNil = previousState == nil
                let statusChanged = hide != previousState?.hide
                let updateCreatedTime = statusChanged
                let usePreviousCreatedTime = previousStateIsNil ? 0 : previousState!.createdTime
                
                let labelIntersection = LabelIntersection(
                    hide: hide,
                    createdTime: updateCreatedTime ? self.frameCounter.getElapsedTimeSeconds() : usePreviousCreatedTime
                )
                labelIntersections[i] = labelIntersection
                self.savedLabelIntersections[collisionId] = labelIntersection
            }
            
            var startIndex = 0
            for i in 0..<tiles.count {
                let tile = tiles[i]
                guard let textLabels = tile.textLabels else { continue }
                let count = textLabels.metaLines.count
                let subArray = Array(labelIntersections[startIndex ..< startIndex + count])
                
                self.intersectionsResultByTiles[i] = subArray
                startIndex += count
            }
            self.newDataFlag = 3
            
            let endTime = CFAbsoluteTimeGetCurrent()
            //let absoluteTimeSpent = endTime - startTime
            //print("timeSpent = \(absoluteTimeSpent)")
            //print("positions = ", spaceDiscretisation.positions)
            self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
        }
        commandBuffer.commit()
    }
}
