//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

struct GeoLabelsWithIntersections {
    let intersections: [Int: [LabelIntersection]]
    let geoLabels: [MetalGeoLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

class ScreenCollisionsDetector {
    private struct SortedGeoLabel {
        let i: Int
        let screenPositions: SIMD2<Float>
        let mapLabelLineCollisionsMeta: MapLabelLineCollisionsMeta
    }
    
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
    private let modelMatrixBufferSize = 30
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    
    // самые актуальные надписи карты
    // для них мы считаем коллизии
    private var geoLabels: [MetalGeoLabels] = []
    
    // закэшированные надписи и результат отработки вычисления пересечений
    private var geoLabelsWithIntersections: GeoLabelsWithIntersections = GeoLabelsWithIntersections(
        intersections: [:], geoLabels: [], bufferingCounter: 0
    )
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if geoLabelsWithIntersections.bufferingCounter <= 0 { return nil }
        
        geoLabelsWithIntersections.bufferingCounter -= 1
        return geoLabelsWithIntersections
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
    
    func setGeoLabels(geoLabels: [MetalGeoLabels]) {
        self.geoLabels = geoLabels
    }
    
    func evaluateTileGeoLabels(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let stackCachingGeoLabels = self.geoLabels
        
        var copyToUniform = lastUniforms
        var inputComputeScreenVertices: [InputComputeScreenVertex] = []
        var modelMatrices = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        var mapLabelLineCollisionsMeta: [MapLabelLineCollisionsMeta] = []
        var labelsTileStartIndices: [Int] = []
        for i in 0..<stackCachingGeoLabels.count {
            let tile = stackCachingGeoLabels[i]
            let tileModelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            modelMatrices[i] = tileModelMatrix
            
            labelsTileStartIndices.append(-1)
            guard let textLabels = tile.textLabels else { continue }
            let inputArray = textLabels.mapLabelLineCollisionsMeta.map {
                label in InputComputeScreenVertex(location: label.localPosition, matrixId: simd_short1(i))
            }
            inputComputeScreenVertices.append(contentsOf: inputArray)
            labelsTileStartIndices[labelsTileStartIndices.count - 1] = textLabels.mapLabelLineCollisionsMeta.count
            mapLabelLineCollisionsMeta.append(contentsOf: textLabels.mapLabelLineCollisionsMeta)
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
            
            var sortedGeoLabels: [SortedGeoLabel] = []
            sortedGeoLabels.reserveCapacity(output.count)
            for i in 0..<output.count {
                let screenPositions = output[i]
                let mapLabelLineCollisionsMeta = mapLabelLineCollisionsMeta[i]
                sortedGeoLabels.append(SortedGeoLabel(
                    i: i,
                    screenPositions: screenPositions,
                    mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
                ))
            }
            sortedGeoLabels.sort(by: { first, second in  first.mapLabelLineCollisionsMeta.sortRank < second.mapLabelLineCollisionsMeta.sortRank })
            
            
            let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
            let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
            var labelIntersections = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: output.count)
            for sorted in sortedGeoLabels {
                let screenPositions = sorted.screenPositions
                let metaLine = sorted.mapLabelLineCollisionsMeta
                let collisionId = metaLine.id
                let added = spaceDiscretisation.addAgent(agent: CollisionAgent(
                    location: SIMD2<Float>(Float(screenPositions.x + 5000), Float(screenPositions.y + 5000)),
                    height: Float((abs(metaLine.measuredText.top) + abs(metaLine.measuredText.bottom)) * metaLine.scale),
                    width: Float(metaLine.measuredText.width * metaLine.scale)
                ))
                
                let hide = added == false
                let labelIntersection: LabelIntersection
                if let previousState = self.savedLabelIntersections[collisionId] {
                    let statusChanged = hide != previousState.hide
                    labelIntersection = LabelIntersection(hide: hide, createdTime: statusChanged ? elapsedTime : previousState.createdTime)
                } else {
                    labelIntersection = LabelIntersection(hide: hide, createdTime: 0)
                }
                
                labelIntersections[sorted.i] = labelIntersection
                self.savedLabelIntersections[collisionId] = labelIntersection
            }
            
            var intersectionsResultByTiles: [Int: [LabelIntersection]] = [:]
            var startIndex = 0
            for i in 0..<stackCachingGeoLabels.count {
                let tile = stackCachingGeoLabels[i]
                guard let textLabels = tile.textLabels else { continue }
                let count = textLabels.mapLabelLineCollisionsMeta.count
                let subArray = Array(labelIntersections[startIndex ..< startIndex + count])
                
                intersectionsResultByTiles[i] = subArray
                startIndex += count
            }
            
            self.geoLabelsWithIntersections = GeoLabelsWithIntersections(
                intersections: intersectionsResultByTiles,
                geoLabels: stackCachingGeoLabels
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let absoluteTimeSpent = endTime - startTime
            //print("timeSpent = \(absoluteTimeSpent)")
            //print("positions = ", spaceDiscretisation.positions)
            self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds))
        }
        commandBuffer.commit()
    }
}
