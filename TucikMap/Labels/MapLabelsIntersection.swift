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
    private let screenUniforms: ScreenUniforms
    private(set) var intersectBuffer: MTLBuffer!
    private var assembledMap: AssembledMap
    
    struct FindIntersections {
        let metaLabels: [MapLabelLineMeta]
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
        screenUniforms: ScreenUniforms,
        assembledMap: AssembledMap
    ) {
        self.metalDevice = metalDevice
        self.computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice)
        self.transformWorldToScreenPositionPipeline = transformWorldToScreenPositionPipeline
        self.metalCommandQueue = metalCommandQueue
        self.screenUniforms = screenUniforms
        self.assembledMap = assembledMap
    }
    
    func computeIntersections(_ intersections: FindIntersections) {
        let metaLabels = intersections.metaLabels
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
        commandBuffer.addCompletedHandler { [weak self] _ in self?.gpuComputeComplete(computeScreenPositions, metaLabels: metaLabels) }
            
        transformWorldToScreenPositionPipeline.selectComputePipeline(computeEncoder: computeEncoder)
        computeLabelScreen.transform(
            uniforms: uniformsBuffer,
            computeEncoder: computeEncoder,
            computeScreenPositions: computeScreenPositions
        )
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    private func gpuComputeComplete(_ computeScreenPositions: ComputeScreenPositions, metaLabels: [MapLabelLineMeta]) {
        let screenPositions = computeScreenPositions.readOutput()
        print("Screen positions evaluated bro I am the best ")
        guard let viewportSize = screenUniforms.viewportSize else { return }
        
        let grid = Grid(width: viewportSize.x, height: viewportSize.y, horizontalDivisions: 3, verticalDivisions: 6)
        var intersectionsArray: [LabelIntersection] = []
        
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
            
            let rectangle = Rectangle(topLeft: topLeft, bottomRight: bottomRight)
            let intersect = grid.insertAndCheckIntersection(rectangle: rectangle)
            intersectionsArray.append(LabelIntersection(intersect: intersect == true))
        }
        
        intersectBuffer = metalDevice.makeBuffer(
            bytes: intersectionsArray,
            length: MemoryLayout<LabelIntersection>.stride * intersectionsArray.count
        )!
    }
}
