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
    let hide: simd_bool
    let createdTime: simd_float1
}

actor MapLabelsIntersectionData {
    private(set) var previousTextLabels: [ParsedTextLabel] = []
    
    private(set) var currentTextLabels: [ParsedTextLabel] = []
    private(set) var currentObjectsMap: [UInt64: LabelIntersection] = [:]
    
    func setPreviousTextLabels(previousTextLabels: [ParsedTextLabel]) {
        self.previousTextLabels = previousTextLabels
    }
    
    func isExpired(label: ParsedTextLabel, currentElapsed: Float) -> Bool {
        guard let saved = currentObjectsMap[label.id] else { return false }
        guard saved.hide == true else { return false }
        return currentElapsed - saved.createdTime > Settings.labelsFadeAnimationTimeSeconds
    }
    
    func saveLabelState(state: LabelIntersection, id: UInt64) {
        currentObjectsMap[id] = state
    }
}

class MapLabelsMaker {
    private let metalDevice: MTLDevice
    private let computeLabelScreen: ComputeLabelScreen
    private let textTools: TextTools
    private let transformWorldToScreenPositionPipeline: TransformWorldToScreenPositionPipeline
    private let metalCommandQueue: MTLCommandQueue
    private var assembledMap: AssembledMap
    private var renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private let camera: Camera
    
    private var mapLabelsIntersectionData: MapLabelsIntersectionData = MapLabelsIntersectionData()
    
    struct TextLabelsFromTile {
        let labels: [ParsedTextLabel]
        let tile: Tile
    }
    
    struct MakeLabels {
        let currentLabels: [TextLabelsFromTile]
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
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter,
        textTools: TextTools,
        camera: Camera
    ) {
        self.camera = camera
        self.metalDevice = metalDevice
        self.computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice)
        self.transformWorldToScreenPositionPipeline = transformWorldToScreenPositionPipeline
        self.metalCommandQueue = metalCommandQueue
        self.assembledMap = assembledMap
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.textTools = textTools
    }
    
    func makeLabelsForRendering(_ labels: MakeLabels) {
        let currentLabels = labels.currentLabels
        let currentElapsedTime = frameCounter.getElapsedTimeSeconds()
        let mapPanning = camera.mapPanning
        let panX = mapPanning.x
        let panY = mapPanning.y
        
        Task {
            var textLabels: [ParsedTextLabel] = []
            for labelsFromTile in currentLabels {
                let tile = labelsFromTile.tile
                let transition = MapMathUtils.getTileTransition(tile: tile, pan: SIMD2<Double>(Double(panX), Double(panY)))
                let scale = transition.scale
                let offset = transition.offset
                
                for label in labelsFromTile.labels {
                    textLabels.append(ParsedTextLabel(
                        id: label.id,
                        localPosition: label.localPosition * scale + offset,
                        nameEn: label.nameEn,
                        scale: label.scale,
                        sortRank: label.sortRank
                    ))
                }
            }
            textLabels.sort(by: { label1, label2 in
                return label1.sortRank < label2.sortRank
            }) // сортировка по возрастанию
            
            var hideCount = 0
            let previousTextLabels = await mapLabelsIntersectionData.previousTextLabels
            for previousTextLabel in previousTextLabels {
                let exist = textLabels.contains(where: { textLabel in textLabel.id == previousTextLabel.id })
                let isExpired = await mapLabelsIntersectionData.isExpired(label: previousTextLabel, currentElapsed: currentElapsedTime)
                if (exist == false && isExpired == false) {
                    textLabels.append(previousTextLabel)
                    hideCount += 1
                }
            }
            await mapLabelsIntersectionData.setPreviousTextLabels(previousTextLabels: textLabels)
            
            if (Settings.debugIntersectionsLabels) { print("textLabels count: \(textLabels.count)") }
            
            guard textLabels.isEmpty == false else { return }
            let result = textTools.mapLabelsAssembler.assemble(
                lines: textLabels.map { line in
                    MapLabelsAssembler.TextLineData(
                        text: line.nameEn,
                        scale: line.scale,
                        localPosition: SIMD2<Float>(line.localPosition)
                    )
                },
                font: textTools.robotoFont.boldFont,
            )
            
            let metaLabels = result.metaLines
            var uniforms = labels.uniforms
            let ids = textLabels.map { label in label.id }
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
                                                                                          labelsAssembled: result,
                                                                                          ids: ids,
                                                                                          hideCount: hideCount,
                                                                                          pan: SIMD2<Float>(panX, panY)
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
    }
    
    private func gpuComputeComplete(_ computeScreenPositions: ComputeScreenPositions,
                                    labelsAssembled: MapLabelsAssembler.Result?,
                                    ids: [UInt64],
                                    hideCount: Int,
                                    pan: SIMD2<Float>
    ) {
        Task {
            guard let labelsAssembled = labelsAssembled else { return }
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
                let labelId = ids[i]
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
                
                let rectangle = Rectangle(id: labelId, topLeft: topLeft, bottomRight: bottomRight)
                rectangles.append(rectangle)
            }
            
            let maxGridX = maxX - minX
            let maxGridY = maxY - minY
            for i in 0..<rectangles.count {
                let rectangle = rectangles[i]
                let shiftedRectangle = Rectangle(
                    id: rectangle.id,
                    topLeft: rectangle.topLeft - SIMD2<Float>(minX, minY),
                    bottomRight: rectangle.bottomRight - SIMD2<Float>(minX, minY)
                )
                rectangles[i] = shiftedRectangle
            }
            
            let horizontalDivisions = Int(ceil(maxGridX / Settings.horizontalGridDivisionSize))
            let verticalDivisions = Int(ceil(maxGridY / Settings.verticalGridDivisionSize))
            
            let currentObjectsMap = await mapLabelsIntersectionData.currentObjectsMap
            let grid = Grid(width: maxGridX, height: maxGridY, horizontalDivisions: horizontalDivisions, verticalDivisions: verticalDivisions)
            var intersectionsArray: [LabelIntersection] = []
            for i in 0..<rectangles.count {
                let rectangle = rectangles[i]
                let shouldBeHiden = i >= rectangles.count - hideCount
                var hide = shouldBeHiden
                if (shouldBeHiden == false) {
                    hide = grid.insertAndCheckIntersection(rectangle: rectangle) == true
                }
                
                if let savedState = currentObjectsMap[rectangle.id] {
                    if (hide == savedState.hide) {
                        intersectionsArray.append(savedState)
                    } else {
                        let newState = LabelIntersection(
                            hide: hide,
                            createdTime: frameCounter.getElapsedTimeSeconds()
                        )
                        await mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                        intersectionsArray.append(newState)
                    }
                } else {
                    if (hide == false) {
                        let newState = LabelIntersection(
                            hide: hide == true,
                            createdTime: frameCounter.getElapsedTimeSeconds()
                        )
                        await mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                        intersectionsArray.append(newState)
                    } else {
                        let newState = LabelIntersection(
                            hide: hide == true,
                            createdTime: frameCounter.getElapsedTimeSeconds() - Settings.labelsFadeAnimationTimeSeconds
                        )
                        await mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                        intersectionsArray.append(newState)
                    }
                }
            }
            
            let intersectBuffer = metalDevice.makeBuffer(
                bytes: intersectionsArray,
                length: MemoryLayout<LabelIntersection>.stride * intersectionsArray.count
            )!
            
            await MainActor.run {
                self.assembledMap.drawLabelsFinal = DrawAssembledMap.DrawLabelsFinal(result: labelsAssembled, pan: pan)
                self.assembledMap.drawLabelsFinal?.result.drawMapLabelsData.intersectionsBuffer = intersectBuffer
                self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds * 2))
            }
        }
    }
}
