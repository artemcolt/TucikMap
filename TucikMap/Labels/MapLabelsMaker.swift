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

class MapLabelsMaker {
    private let metalDevice: MTLDevice
    private let computeLabelScreen: ComputeLabelScreen
    private let textTools: TextTools
    private let transformWorldToScreenPositionPipeline: TransformWorldToScreenPositionPipeline
    private let metalCommandQueue: MTLCommandQueue
    private var assembledMap: AssembledMap
    private var renderFrameCount: RenderFrameCount
    private let mapZoomState: MapZoomState
    
    private var unionLabels: UnionLabels = UnionLabels()
    private var currentObjectsMap: [UInt64: LabelIntersection] = [:]
    private var previousTiles: [Tile] = []
    private var previousTextLabels: [LabelWithTileLink] = []
    
    private let asyncStream: AsyncStream<MakeLabels>
    private let continuation: AsyncStream<MakeLabels>.Continuation
    
    struct UnionLabels {
        var labelsAssemblingResult: MapLabelsAssembler.Result? = nil
        var tiles: [Tile] = []
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
        let mapPanning: SIMD3<Double>
        let lastUniforms: Uniforms
        let viewportSize: SIMD2<Float>
    }
    
    struct LabelLine {
        let screenPos: SIMD2<Float>
        let measuredText: MeasuredText
        let scale: Float
    }
    
    struct DrawLabelsFinal {
        var result: MapLabelsAssembler.Result
        var tiles: [Tile]
    }
    
    init(
        metalDevice: MTLDevice,
        metalCommandQueue: MTLCommandQueue,
        transformWorldToScreenPositionPipeline: TransformWorldToScreenPositionPipeline,
        assembledMap: AssembledMap,
        renderFrameCount: RenderFrameCount,
        textTools: TextTools,
        mapZoomState: MapZoomState,
    ) {
        self.metalDevice = metalDevice
        self.computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice)
        self.transformWorldToScreenPositionPipeline = transformWorldToScreenPositionPipeline
        self.metalCommandQueue = metalCommandQueue
        self.assembledMap = assembledMap
        self.renderFrameCount = renderFrameCount
        self.textTools = textTools
        self.mapZoomState = mapZoomState
        (asyncStream, continuation) = AsyncStream<MakeLabels>.makeStream()
        
        Task {
            for await make in asyncStream {
                guard let result = makeLabelsForRendering(make) else { continue }
                
                await MainActor.run {
                    self.assembledMap.drawLabelsFinal = result.drawLabelsFinal
                    self.renderFrameCount.renderNextNSeconds(Double(Settings.labelsFadeAnimationTimeSeconds * 2))
                }
            }
        }
    }
    
    func queueLabelsUpdating(_ labels: MakeLabels) {
        continuation.yield(labels)
    }
    
    struct LabelWithTileLink {
        let parseLabel: ParsedTextLabel
        let tileIndex: simd_int1
    }
    
    private func isExpired(label: ParsedTextLabel, currentElapsed: Float) -> Bool {
        guard let saved = currentObjectsMap[label.id] else { return false }
        guard saved.hide == true else { return false }
        return currentElapsed - saved.createdTime > Settings.labelsFadeAnimationTimeSeconds
    }
    
    private func handleNewLabels(newLabels: [MapLabelsMaker.TextLabelsFromTile], currentElapsedTime: Float) {
        var textLabels: [LabelWithTileLink] = []
        var tiles: [Tile] = []
        for labelsFromTile in newLabels {
            let tileIndex = simd_int1(tiles.count)
            let labelsWithTileLink = labelsFromTile.labels.map { label in LabelWithTileLink(parseLabel: label, tileIndex: tileIndex) }
            textLabels.append(contentsOf: labelsWithTileLink)
            tiles.append(labelsFromTile.tile)
        }
        
        textLabels.sort(by: { label1, label2 in
            return label1.parseLabel.sortRank < label2.parseLabel.sortRank
        }) // сортировка по возрастанию
        
        var hideCount = 0
        let tilesStartCount = tiles.count
        var addedPreviousTileIndices: [simd_int1] = []
        for previousTextLabel in previousTextLabels {
            let exist = textLabels.contains(where: { textLabel in textLabel.parseLabel.id == previousTextLabel.parseLabel.id })
            let isExpired = isExpired(label: previousTextLabel.parseLabel, currentElapsed: currentElapsedTime)
            if (exist == false && isExpired == false) {
                if (addedPreviousTileIndices.contains(previousTextLabel.tileIndex) == false) {
                    tiles.append(previousTiles[Int(previousTextLabel.tileIndex)])
                    addedPreviousTileIndices.append(previousTextLabel.tileIndex)
                }
                
                let indexOf = addedPreviousTileIndices.firstIndex(of: previousTextLabel.tileIndex)!
                textLabels.append(LabelWithTileLink(
                    parseLabel: previousTextLabel.parseLabel,
                    tileIndex: simd_int1(indexOf + tilesStartCount)
                ))
                hideCount += 1
            }
        }
        previousTiles = tiles
        previousTextLabels = textLabels
        
        
        let ids: [UInt64] = textLabels.map { label in label.parseLabel.id }
        if (Settings.debugIntersectionsLabels) { print("textLabels count: \(textLabels.count)") }
        
        guard textLabels.isEmpty == false else { return }
        let labelsAssemblingResult = textTools.mapLabelsAssembler.assemble(
            lines: textLabels.map { line in
                let parseLabel = line.parseLabel
                return MapLabelsAssembler.TextLineData(
                    text: parseLabel.nameEn,
                    scale: parseLabel.scale,
                    localPosition: SIMD2<Float>(parseLabel.localPosition),
                    tileIndex: line.tileIndex
                )
            },
            font: textTools.robotoFont.boldFont,
        )
        
        unionLabels = UnionLabels(
            labelsAssemblingResult: labelsAssemblingResult,
            tiles: tiles,
            ids: ids,
            hideCount: hideCount
        )
    }
    
    private func makeLabelsForRendering(_ labels: MakeLabels) -> MakingResult? {
        let start = DispatchTime.now()
        
        let currentElapsedTime = labels.currentElapsedTime
        if let newLabels = labels.newLabels {
            handleNewLabels(newLabels: newLabels, currentElapsedTime: currentElapsedTime)
        }
        if (Settings.debugIntersectionsLabels) { print("Make Labels for rendering") }
        
        guard var labelsAssemblingResult = unionLabels.labelsAssemblingResult else { return nil }
        let metaLabels = labelsAssemblingResult.metaLines
        guard metaLabels.isEmpty == false else { return nil }
        
        var minX: Float = 0
        var maxX: Float = 0
        var minY: Float = 0
        var maxY: Float = 0
        
        let lastUniforms = labels.lastUniforms
        let lastViewportSize = labels.viewportSize
        let pan = labels.mapPanning
        let pvMatrix = lastUniforms.projectionMatrix * lastUniforms.viewMatrix
        let tiles = unionLabels.tiles
        var rectangles: [Rectangle] = []
        var modelMatricesMap: [Int: matrix_float4x4] = [:]
        for i in 0..<metaLabels.count {
            let metaLine = metaLabels[i]
            let tileIndex = Int(metaLine.tileIndex)
            var modelMatrix = modelMatricesMap[tileIndex]
            if modelMatrix == nil {
                modelMatrix = MapMathUtils.getTileModelMatrix(tile: tiles[tileIndex], mapZoomState: mapZoomState, pan: pan)
                modelMatricesMap[tileIndex] = modelMatrix
            }
            let worldPos = metaLabels[i].worldPosition
            let translatedWorldPos = modelMatrix! * SIMD4<Float>(worldPos.x, worldPos.y, 0, 1)
            let worldPosition = SIMD4<Float>(translatedWorldPos.x + Float(pan.x), translatedWorldPos.y + Float(pan.y), 0, 1)
            let clipPos = pvMatrix * worldPosition;
            let ndc = SIMD3<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
            let viewportSize = lastViewportSize;
            let viewportWidth = viewportSize.x;
            let viewportHeight = viewportSize.y;
            let screenX = ((ndc.x + 1) / 2) * viewportWidth;
            let screenY = ((ndc.y + 1) / 2) * viewportHeight;
            let screenPosition = SIMD2<Float>(screenX, screenY);
            
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
        
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        if (Settings.debugIntersectionsLabels) { print("Creating labels time seconds: \(timeInterval)") }
        
        let horizontalDivisions = Int(ceil(maxGridX / Settings.horizontalGridDivisionSize))
        let verticalDivisions = Int(ceil(maxGridY / Settings.verticalGridDivisionSize))
        
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
                        createdTime: currentElapsedTime + Float(timeInterval)
                    )
                    currentObjectsMap[rectangle.id] = newState
                    intersectionsArray.append(newState)
                }
            } else {
                if (hide == false) {
                    let newState = LabelIntersection(
                        hide: hide == true,
                        createdTime: currentElapsedTime + Float(timeInterval)
                    )
                    currentObjectsMap[rectangle.id] = newState
                    intersectionsArray.append(newState)
                } else {
                    let newState = LabelIntersection(
                        hide: hide == true,
                        createdTime: currentElapsedTime - Settings.labelsFadeAnimationTimeSeconds
                    )
                    currentObjectsMap[rectangle.id] = newState
                    intersectionsArray.append(newState)
                }
            }
        }
        
        let intersectBuffer = metalDevice.makeBuffer(
            bytes: intersectionsArray,
            length: MemoryLayout<LabelIntersection>.stride * intersectionsArray.count
        )!
        
        
        labelsAssemblingResult.drawMapLabelsData.intersectionsBuffer = intersectBuffer
        return MakingResult(
            drawLabelsFinal: MapLabelsMaker.DrawLabelsFinal(
                result: labelsAssemblingResult,
                tiles: unionLabels.tiles
            )
        )
    }
    
    struct MakingResult {
        let drawLabelsFinal: MapLabelsMaker.DrawLabelsFinal
    }
}
