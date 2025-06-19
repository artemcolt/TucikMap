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

class MapLabelsIntersectionData {
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
    
    private var mapLabelsIntersectionData: MapLabelsIntersectionData = MapLabelsIntersectionData()
    private var unionLabels: UnionLabels = UnionLabels()
    
    private let asyncStream: AsyncStream<MakeLabels>
    private let continuation: AsyncStream<MakeLabels>.Continuation
    
    struct UnionLabels {
        var labelsAssemblingResult: MapLabelsAssembler.Result? = nil
        var ids: [UInt64] = []
        var hideCount: Int = 0
    }
    
    struct TextLabelsFromTile {
        let labels: [ParsedTextLabel]
        let tile: Tile
    }
    
    struct MakeLabels {
        let newLabels: [TextLabelsFromTile]?
        let currentElapsedTime: Float
        let mapPanning: SIMD3<Float>
        let lastUniforms: Uniforms
        let viewportSize: SIMD2<Float>
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
        textTools: TextTools,
    ) {
        self.metalDevice = metalDevice
        self.computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice)
        self.transformWorldToScreenPositionPipeline = transformWorldToScreenPositionPipeline
        self.metalCommandQueue = metalCommandQueue
        self.assembledMap = assembledMap
        self.renderFrameCount = renderFrameCount
        self.textTools = textTools
        (asyncStream, continuation) = AsyncStream<MakeLabels>.makeStream()
        
        Task {
            for await make in asyncStream {
                guard let result = makeLabelsForRendering(make) else { continue }
                
                await MainActor.run {
                    self.assembledMap.drawLabelsFinal = result.drawLabelsFinal
                    self.assembledMap.drawLabelsFinal?.result.drawMapLabelsData.intersectionsBuffer = result.intersectionBuffer
                    self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds * 2))
                }
            }
        }
    }
    
    func queueLabelsUpdating(_ labels: MakeLabels) {
        continuation.yield(labels)
    }
    
    private func handleNewLabels(newLabels: [MapLabelsMaker.TextLabelsFromTile], currentElapsedTime: Float) {
        var textLabels: [ParsedTextLabel] = []
        for labelsFromTile in newLabels {
            let tile = labelsFromTile.tile
            let transition = MapMathUtils.getTileTransition(tile: tile)
            let scale = transition.scale
            let tileWorld = transition.tileWorld
            
            for label in labelsFromTile.labels {
                textLabels.append(ParsedTextLabel(
                    id: label.id,
                    localPosition: label.localPosition * scale + tileWorld,
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
        let previousTextLabels = mapLabelsIntersectionData.previousTextLabels
        for previousTextLabel in previousTextLabels {
            let exist = textLabels.contains(where: { textLabel in textLabel.id == previousTextLabel.id })
            let isExpired = mapLabelsIntersectionData.isExpired(label: previousTextLabel, currentElapsed: currentElapsedTime)
            if (exist == false && isExpired == false) {
                textLabels.append(previousTextLabel)
                hideCount += 1
            }
        }
        mapLabelsIntersectionData.setPreviousTextLabels(previousTextLabels: textLabels)
        
        if (Settings.debugIntersectionsLabels) { print("textLabels count: \(textLabels.count)") }
        
        guard textLabels.isEmpty == false else { return }
        let labelsAssemblingResult = textTools.mapLabelsAssembler.assemble(
            lines: textLabels.map { line in
                MapLabelsAssembler.TextLineData(
                    text: line.nameEn,
                    scale: line.scale,
                    localPosition: SIMD2<Float>(line.localPosition)
                )
            },
            font: textTools.robotoFont.boldFont,
        )
        
        unionLabels = UnionLabels(
            labelsAssemblingResult: labelsAssemblingResult,
            ids: textLabels.map { label in label.id },
            hideCount: hideCount,
        )
    }
    
    private func makeLabelsForRendering(_ labels: MakeLabels) -> MakingResult? {
        let start = DispatchTime.now()
        
        let currentElapsedTime = labels.currentElapsedTime
        let mapPanning = labels.mapPanning
        let pan = SIMD2<Float>(mapPanning.x, mapPanning.y)
        let lastUniforms = labels.lastUniforms
        let lastViewportSize = labels.viewportSize
        if let newLabels = labels.newLabels {
            handleNewLabels(newLabels: newLabels, currentElapsedTime: currentElapsedTime)
        }
        if (Settings.debugIntersectionsLabels) { print("Make Labels for rendering") }
        
        
        guard let labelsAssemblingResult = unionLabels.labelsAssemblingResult else { return nil }
        let metaLabels = labelsAssemblingResult.metaLines
        guard metaLabels.isEmpty == false else { return nil }
        
        var minX: Float = 0
        var maxX: Float = 0
        var minY: Float = 0
        var maxY: Float = 0
        
        let pvMatrix = lastUniforms.projectionMatrix * lastUniforms.viewMatrix
        var rectangles: [Rectangle] = []
        for i in 0..<metaLabels.count {
            let worldPosSimd2 = metaLabels[i].worldPosition + pan
            let worldPosition = SIMD4<Float>(worldPosSimd2.x, worldPosSimd2.y, 0, 1)
            let clipPos = pvMatrix * worldPosition;
            let ndc = SIMD3<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
            let viewportSize = lastViewportSize;
            let viewportWidth = viewportSize.x;
            let viewportHeight = viewportSize.y;
            let screenX = ((ndc.x + 1) / 2) * viewportWidth;
            let screenY = ((ndc.y + 1) / 2) * viewportHeight;
            let screenPosition = SIMD2<Float>(screenX, screenY);
            
            let metaLine = metaLabels[i]
            let labelId = unionLabels.ids[i]
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
        
        let currentObjectsMap = mapLabelsIntersectionData.currentObjectsMap
        let grid = Grid(width: maxGridX, height: maxGridY, horizontalDivisions: horizontalDivisions, verticalDivisions: verticalDivisions)
        var intersectionsArray: [LabelIntersection] = []
        for i in 0..<rectangles.count {
            let rectangle = rectangles[i]
            let shouldBeHiden = i >= rectangles.count - unionLabels.hideCount
            var hide = shouldBeHiden
            if (shouldBeHiden == false) {
                hide = grid.insertAndCheckIntersection(rectangle: rectangle) == true
            }
            
            if let savedState = currentObjectsMap[rectangle.id] {
                if (hide == savedState.hide) {
                    intersectionsArray.append(savedState)
                } else {
                    let newState = LabelIntersection(
                        hide: hide == true,
                        createdTime: currentElapsedTime
                    )
                    mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                    intersectionsArray.append(newState)
                }
            } else {
                if (hide == false) {
                    let newState = LabelIntersection(
                        hide: hide == true,
                        createdTime: currentElapsedTime
                    )
                    mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                    intersectionsArray.append(newState)
                } else {
                    let newState = LabelIntersection(
                        hide: hide == true,
                        createdTime: currentElapsedTime - Settings.labelsFadeAnimationTimeSeconds
                    )
                    mapLabelsIntersectionData.saveLabelState(state: newState, id: rectangle.id)
                    intersectionsArray.append(newState)
                }
            }
        }
        
        let intersectBuffer = metalDevice.makeBuffer(
            bytes: intersectionsArray,
            length: MemoryLayout<LabelIntersection>.stride * intersectionsArray.count
        )!
        
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        if (Settings.debugIntersectionsLabels) { print("Creating labels time seconds: \(timeInterval)") }
        
        return MakingResult(
            drawLabelsFinal: DrawAssembledMap.DrawLabelsFinal(result: labelsAssemblingResult),
            intersectionBuffer: intersectBuffer
        )
    }
    
    struct MakingResult {
        let drawLabelsFinal: DrawAssembledMap.DrawLabelsFinal
        let intersectionBuffer: MTLBuffer
    }
}
