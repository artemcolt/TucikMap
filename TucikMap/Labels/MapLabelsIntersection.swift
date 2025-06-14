//
//  MapLablesCollision.swift
//  TucikMap
//
//  Created by Artem on 6/11/25.
//

import Foundation
import MetalKit
import SwiftUI

struct LabelIntersection {
    let intersect: simd_bool
}

class MapLabelsIntersection {
    private let metalDevice: MTLDevice
    private let computeLabelScreen: ComputeLabelScreen
    private let transformWorldToScreenPositionPipeline: TransformWorldToScreenPositionPipeline
    private let metalCommandQueue: MTLCommandQueue
    private var assembledMap: AssembledMap
    private var renderFrameCount: RenderFrameCount
    
    struct FindIntersections {
        let labelsAssembled: MapLabelsAssembler.Result
        let uniforms: Uniforms
    }
    
    struct LabelLine {
        let screenPos: SIMD2<Float>
        let measuredText: MeasuredText
        let scale: Float
    }
    
    init(
        metalDevice: MTLDevice,
        metalCommandQueue: MTLCommandQueue,
        transformWorldToScreenPositionPipeline: TransformWorldToScreenPositionPipeline,
        assembledMap: AssembledMap,
        renderFrameCount: RenderFrameCount
    ) {
        self.metalDevice = metalDevice
        self.computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice)
        self.transformWorldToScreenPositionPipeline = transformWorldToScreenPositionPipeline
        self.metalCommandQueue = metalCommandQueue
        self.assembledMap = assembledMap
        self.renderFrameCount = renderFrameCount
    }
    
    func computeIntersections(_ intersections: FindIntersections) {
        let metaLabels = intersections.labelsAssembled.metaLines
        var uniforms = intersections.uniforms
        guard metaLabels.isEmpty == false else { return }
        
        let worldPositions = metaLabels.map {meta in meta.worldPosition}
        let uniformsBuffer = metalDevice.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride)!
        let inputBuffer = metalDevice.makeBuffer(bytes: worldPositions, length: MemoryLayout<SIMD2<Float>>.stride * worldPositions.count)!
        let outputBuffer = metalDevice.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * worldPositions.count)!
        let computeScreenPositions = ComputeScreenPositions(
            inputBuffer: inputBuffer,
            outputBuffer: outputBuffer,
            vertexCount: worldPositions.count
        )
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        commandBuffer.addCompletedHandler { [weak self] _ in self?.gpuComputeComplete(computeScreenPositions,
                                                                                      labelsAssembled: intersections.labelsAssembled
        ) }
            
        transformWorldToScreenPositionPipeline.selectComputePipeline(computeEncoder: computeEncoder)
        computeLabelScreen.transform(
            uniforms: uniformsBuffer,
            computeEncoder: computeEncoder,
            computeScreenPositions: computeScreenPositions
        )
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    private func gpuComputeComplete(_ computeScreenPositions: ComputeScreenPositions, labelsAssembled: MapLabelsAssembler.Result) {
        let screenPositions = computeScreenPositions.readOutput()
        if (Settings.debugIntersectionsLabels) { print("Screen positions evaluated") }
        
        let metaLabels = labelsAssembled.metaLines
        var minX: Float = 0
        var maxX: Float = 0
        var minY: Float = 0
        var maxY: Float = 0
        var rectangles: [Rectangle] = []
        for i in 0..<screenPositions.count {
            let screenPosition = screenPositions[i]
            let metaLine = metaLabels[i]
            let halfTextWidth: Float = metaLine.measuredText.width / 2
            
            let topLeft = SIMD2<Float>(
                screenPosition.x - halfTextWidth * metaLine.scale,
                screenPosition.y + metaLine.measuredText.top * metaLine.scale
            )
            let bottomRight = SIMD2<Float>(
                screenPosition.x + halfTextWidth * metaLine.scale,
                screenPosition.y - abs(metaLine.measuredText.bottom) * metaLine.scale
            )
            
            minX = min(min(topLeft.x, bottomRight.x), minX)
            maxX = max(max(topLeft.x, bottomRight.x), maxX)
            minY = min(min(topLeft.y, bottomRight.y), minY)
            maxY = max(max(topLeft.y, bottomRight.y), maxY)
            
            let rectangle = Rectangle(topLeft: topLeft, bottomRight: bottomRight)
            rectangles.append(rectangle)
        }
        
        let maxGridX = maxX - minX
        let maxGridY = maxY - minY
        for i in 0..<rectangles.count {
            let rectangle = rectangles[i]
            let shiftedRectangle = Rectangle(
                topLeft: rectangle.topLeft - SIMD2<Float>(minX, minY),
                bottomRight: rectangle.bottomRight - SIMD2<Float>(minX, minY)
            )
            rectangles[i] = shiftedRectangle
        }
        
        let horizontalDivisions = Int(ceil(maxGridX / 500))
        let verticalDivisions = Int(ceil(maxGridY / 300))
        
        let grid = Grid(width: maxGridX, height: maxGridY, horizontalDivisions: horizontalDivisions, verticalDivisions: verticalDivisions)
        var intersectionsArray: [LabelIntersection] = []
        for rectangle in rectangles {
            let intersect = grid.insertAndCheckIntersection(rectangle: rectangle)
            intersectionsArray.append(LabelIntersection(intersect: intersect == true))
        }
        
        let intersectBuffer = metalDevice.makeBuffer(
            bytes: intersectionsArray,
            length: MemoryLayout<LabelIntersection>.stride * intersectionsArray.count
        )!
        
        DispatchQueue.main.async {
            self.assembledMap.labelsAssembled = labelsAssembled
            self.assembledMap.labelsAssembled?.drawMapLabelsData.intersectionsBuffer = intersectBuffer
            self.renderFrameCount.renderNextNFrames(Settings.maxBuffersInFlight)
        }
        
    }
}
