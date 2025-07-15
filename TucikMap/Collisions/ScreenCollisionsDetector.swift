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

struct RoadLabel {
    let name: String
    let localPoints: [SIMD2<Float>]
    let measuredText: MeasuredText
    let scale: Float
    let pathLen: Float
}

struct RoadLabels {
    let items: [RoadLabel]
    var draw: MapRoadLabelsAssembler.DrawMapLabelsData?
    var tile: Tile
}

struct RenderingCurrentRoadLabels {
    let draw: MapRoadLabelsAssembler.DrawMapLabelsData
    let lineToStartAt: [MapRoadLabelsAssembler.LineToStartAt]
    let startAt: [MapRoadLabelsAssembler.StartRoadAt]
    let tile: Tile
}

struct RenderingRoads {
    let renderingCurrentRoadLabels: [RenderingCurrentRoadLabels]
    var bufferingCounter: Int
}

class ScreenCollisionsDetector {
    private let computeLabelScreen: ComputeLabelScreen
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private var projectPoints: ProjectPoints!
    let handleGeoLabels: HandleGeoLabels
    
    private var roadLabelsByTiles: [RoadLabels] = []
    
    private var currentRenderingRoads: RenderingRoads = RenderingRoads(renderingCurrentRoadLabels: [], bufferingCounter: 0)
    func getRenderingCurrentRoadLabels() -> RenderingRoads? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if currentRenderingRoads.bufferingCounter <= 0 { return nil }
        
        currentRenderingRoads.bufferingCounter -= 1
        return currentRenderingRoads
    }
    
    
    init(
        metalDevice: MTLDevice,
        library: MTLLibrary,
        metalCommandQueue: MTLCommandQueue,
        mapZoomState: MapZoomState,
        renderFrameCount: RenderFrameCount,
        frameCounter: FrameCounter
    ) {
        handleGeoLabels = HandleGeoLabels(
            frameCounter: frameCounter,
            mapZoomState: mapZoomState,
            renderFrameCount: renderFrameCount
        )
        computeLabelScreen = ComputeLabelScreen(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.projectPoints = ProjectPoints(
            computeLabelScreen: computeLabelScreen,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
    }
    
    func setRoadLabels(roadLabelsByTiles: [RoadLabels]) {
        self.roadLabelsByTiles = roadLabelsByTiles
    }
    
    private func localTilePositionToScreenSpacePosition(modelMatrix: matrix_float4x4, localPosition: SIMD2<Float>, worldUniforms: Uniforms) -> SIMD2<Float> {
        let worldLabelPos = modelMatrix * SIMD4<Float>(localPosition.x, localPosition.y, 0.0, 1.0);
        let clipPos = worldUniforms.projectionMatrix * worldUniforms.viewMatrix * worldLabelPos;
        let ndc = SIMD3<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
       
        let viewportSize = worldUniforms.viewportSize;
        let viewportWidth = viewportSize.x;
        let viewportHeight = viewportSize.y;
        let screenX = ((ndc.x + 1) / 2) * viewportWidth;
        let screenY = ((ndc.y + 1) / 2) * viewportHeight;
        let screenPos = SIMD2<Float>(screenX, screenY);
        return screenPos;
    }
    
    func getScreenArcPosition(
        worldArcPos: Float,
        localPositions: [simd_float2],
        output: [simd_float2],
        nextResultIndex: Int,
        outputIndexShift: Int,
        modelMatrix: simd_float4x4,
        uniforms: Uniforms
    ) -> Float {
        var remaining = worldArcPos
        var screenCum: Float = 0
        let count = localPositions.count
        for i in 0..<count - 1 {
            let current = localPositions[i]
            let next = localPositions[i + 1]
            let len = length(next - current)
            if remaining < len || i == count - 2 {
                let inSegmentWorldLen = remaining
                let direction = normalize(next - current)
                let worldPoint = current + direction * inSegmentWorldLen
                let screenPoint = localTilePositionToScreenSpacePosition(modelMatrix: modelMatrix, localPosition: worldPoint, worldUniforms: uniforms)
                let currentScreen = output[nextResultIndex + i + outputIndexShift]
                let inSegmentScreenLen = length(screenPoint - currentScreen)
                return screenCum + inSegmentScreenLen
            }
            remaining -= len
            let currentScreen = output[nextResultIndex + i + outputIndexShift]
            let nextScreen = output[nextResultIndex + i + outputIndexShift + 1]
            let screenLen = length(nextScreen - currentScreen)
            screenCum += screenLen
        }
        return screenCum
    }
    
    private func onPointsReady(result: ProjectPoints.Result) {
        handleGeoLabels.onPointsReady(result: result)
        
        let uniforms = result.input.uniforms
        let mapPanning = result.input.mapPanning
        let input = result.input
        let output = result.output
        let nextResultIndex = input.nextResultsIndex
        let roadLabelsByTiles = input.roadLabelsByTiles
        var renderingCurrentRoadLabels: [RenderingCurrentRoadLabels] = []
        var outputIndexShift = 0
        for tileRoadLabels in roadLabelsByTiles {
            guard var draw = tileRoadLabels.draw else { continue }
            
            let modelMatrix = tileRoadLabels.tile.getModelMatrix(mapZoomState: mapZoomState, pan: mapPanning)
            var lineToStartFloats: [MapRoadLabelsAssembler.LineToStartAt] = []
            var startRoadLabelsAtFull: [MapRoadLabelsAssembler.StartRoadAt] = []
            var maxInstances = 0
            for roadLabelIndex in 0..<tileRoadLabels.items.count {
                let roadLabel = tileRoadLabels.items[roadLabelIndex]
                let worldPathLen = roadLabel.pathLen
                let measuredText = roadLabel.measuredText
                let textScreenWidth = measuredText.width * roadLabel.scale + Settings.roadLabelScreenSpacing
                var startRoadLabelsAt: [MapRoadLabelsAssembler.StartRoadAt] = []
                let localPositions = roadLabel.localPoints
                let count = roadLabel.localPoints.count
//                
//                
//                var screenPathLen = Float(0);
//                for i in 0..<count-1 {
//                    let currentScreen = output[nextResultIndex + i + outputIndexShift]
//                    let nextScreen = output[nextResultIndex + i + outputIndexShift + 1]
//                    let screenLen = length(nextScreen - currentScreen)
//                    screenPathLen += screenLen
//                }
//                
//                //print("screenPathLen = ", screenPathLen)
//                
//                // Now, perform the subdivision to find all valid factors.
//                var queue: [(Float, Float)] = [(0.0, worldPathLen)]
//                var centers: [Float] = [] // World arc positions for centers
//                var intervals: [(Float, Float)] = [] // Screen [start, end] intervals for placed texts
//
//                while !queue.isEmpty {
//                    let segment = queue.removeFirst() // Breadth-first
//                    let midWorld = (segment.0 + segment.1) / 2
//                    let screenMid = getScreenArcPosition(worldArcPos: midWorld, localPositions: localPositions, output: output, nextResultIndex: nextResultIndex, outputIndexShift: outputIndexShift, modelMatrix: modelMatrix, uniforms: uniforms)
//                    let halfText = textScreenWidth / 2
//                    let textStart = screenMid - halfText
//                    let textEnd = screenMid + halfText
//                    
//                    if textStart < 0 || textEnd > screenPathLen {
//                        continue
//                    }
//                    
//                    var overlaps = false
//                    for interval in intervals {
//                        let existingStart = interval.0
//                        let existingEnd = interval.1
//                        if max(textStart, existingStart) < min(textEnd, existingEnd) {
//                            overlaps = true
//                            break
//                        }
//                    }
//                    
//                    if !overlaps {
//                        centers.append(midWorld)
//                        intervals.append((textStart, textEnd))
//                        queue.append((segment.0, midWorld))
//                        queue.append((midWorld, segment.1))
//                    }
//                }
//
//                let factors = centers.map { $0 / worldPathLen }.sorted()
                
                let factors: [Float] = [0.5];
                
                //print(roadLabelIndex, " ", factors)
                
                outputIndexShift += count
                if factors.count > maxInstances {
                    maxInstances = factors.count
                }
                
                for factor in factors {
                    startRoadLabelsAt.append(MapRoadLabelsAssembler.StartRoadAt(startAt: factor))
                }
                
                lineToStartFloats.append(MapRoadLabelsAssembler.LineToStartAt(
                    index: simd_int1(startRoadLabelsAtFull.count),
                    count: simd_int1(startRoadLabelsAt.count)
                ))
                startRoadLabelsAtFull.append(contentsOf: startRoadLabelsAt)
            }
            
            draw.maxInstances = maxInstances
                        
            renderingCurrentRoadLabels.append(RenderingCurrentRoadLabels(
                draw: draw,
                lineToStartAt: lineToStartFloats,
                startAt: startRoadLabelsAtFull,
                tile: tileRoadLabels.tile
            ))
        }
        
        self.currentRenderingRoads = RenderingRoads(
            renderingCurrentRoadLabels: renderingCurrentRoadLabels,
            bufferingCounter: Settings.maxBuffersInFlight
        )
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        let result = handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning)
        if result.recallLater {
            return true
        }
        
        var forCompute: [InputComputeScreenVertex] = []
        for i in 0..<roadLabelsByTiles.count {
            let roadLabelsOfTile = roadLabelsByTiles[i]
            let tileRoadsLabels = roadLabelsOfTile.items
            for tileRoad in tileRoadsLabels {
                let computeInput = tileRoad.localPoints.map { localPoint in
                    InputComputeScreenVertex(location: localPoint, matrixId: simd_short1(i))
                }
                forCompute.append(contentsOf: computeInput)
            }
        }
        
        var inputComputeScreenVertices = result.inputComputeScreenVertices
        let nextResultsIndex = inputComputeScreenVertices.count
        inputComputeScreenVertices.append(contentsOf: forCompute)
        
        projectPoints.project(input: ProjectPoints.ProjectInput(
            modelMatrices: result.modelMatrices,
            uniforms: lastUniforms,
            mapPanning: mapPanning,
            inputComputeScreenVertices: inputComputeScreenVertices,
            
            metalGeoLabels: result.metalGeoLabels,
            mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
            actualLabelsIds: handleGeoLabels.actualLabelsIds,
            geoLabelsSize: result.geoLabelsSize,
            
            nextResultsIndex: nextResultsIndex,
            roadLabelsByTiles: roadLabelsByTiles,
        ))
        
        return false
    }
}
