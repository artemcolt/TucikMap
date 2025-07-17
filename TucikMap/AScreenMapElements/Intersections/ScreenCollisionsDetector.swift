//
//  ScreenCollisionsDetector.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

struct LabelIntersection {
    let hide: Bool
    let createdTime: Float
}

struct GeoLabelsWithIntersections {
    let intersections: [Int: [LabelIntersection]]
    let geoLabels: [MetalGeoLabels]
    var bufferingCounter: Int = Settings.maxBuffersInFlight
}

struct DrawTileRoadLabelsPrep {
    let lineToStartAt: [MapRoadLabelsAssembler.LineToStartAt]
    let startAt: [MapRoadLabelsAssembler.StartRoadAt]
    let metalRoadLabels: MetalRoadLabels
    let maxInstances: Int
}

// Rendering road labels tripple buffering
struct RenderingRoadLabelsTB {
    let tilesPrepare: [DrawTileRoadLabelsPrep]
    var bufferingCounter: Int
}

class ScreenCollisionsDetector {
    private let computeScreenPositions: ComputeScreenPositions
    private let metalDevice: MTLDevice
    private let metalCommandQueue: MTLCommandQueue
    private let mapZoomState: MapZoomState
    private let renderFrameCount: RenderFrameCount
    private let frameCounter: FrameCounter
    private var projectPoints: CombinedCompSP!
    private let handleGeoLabels: HandleGeoLabels
    
    private var roadLabelsByTiles: [MetalRoadLabels] = []
    private var viewportSize: SIMD2<Float> = SIMD2<Float>()
    
    var testPoints: [SIMD2<Float>] = []
    
    private var currentRenderingRoads: RenderingRoadLabelsTB = RenderingRoadLabelsTB(tilesPrepare: [], bufferingCounter: 0)
    func getRoadLabels() -> RenderingRoadLabelsTB? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if currentRenderingRoads.bufferingCounter <= 0 { return nil }
        
        currentRenderingRoads.bufferingCounter -= 1
        return currentRenderingRoads
    }
    
    func getLabelsWithIntersections() -> GeoLabelsWithIntersections? {
        return handleGeoLabels.getLabelsWithIntersections()
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
        computeScreenPositions = ComputeScreenPositions(metalDevice: metalDevice, library: library)
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue
        self.mapZoomState = mapZoomState
        self.renderFrameCount = renderFrameCount
        self.frameCounter = frameCounter
        self.projectPoints = CombinedCompSP(
            computeScreenPositions: computeScreenPositions,
            metalDevice: metalDevice,
            metalCommandQueue: metalCommandQueue,
            onPointsReady: self.onPointsReady
        )
    }
    
    func newState(roadLabelsByTiles: [MetalRoadLabels], geoLabels: [MetalGeoLabels], view: MTKView) {
        self.roadLabelsByTiles = roadLabelsByTiles
        self.handleGeoLabels.setGeoLabels(geoLabels: geoLabels)
        viewportSize = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
    }
    
    private func localTilePositionToScreenSpacePosition(modelMatrix: matrix_float4x4,
                                                        localPosition: SIMD2<Float>,
                                                        worldUniforms: Uniforms) -> SIMD2<Float> {
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
    
    private func onPointsReady(result: CombinedCompSP.Result) {
        testPoints = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let spaceDiscretisation = SpaceDiscretisation(clusterSize: 50, count: 300)
        handleGeoLabels.onPointsReady(result: result, spaceDiscretisation: spaceDiscretisation)
        
        let uniforms                = result.uniforms
        let mapPanning              = result.mapPanning
        let output                  = result.output
        let startRoadResultsIndex   = result.startRoadResultsIndex
        let metalRoadLabelsTiles    = result.metalRoadLabelsTiles // по тайлам метки дорог
        var outputIndexShift        = 0
        
        var renderingCurrentRoadLabels  : [DrawTileRoadLabelsPrep] = []
        
        for metalRoadLabels in metalRoadLabelsTiles {
            guard let roadLabels    = metalRoadLabels.roadLabels else { continue }
            let modelMatrix         = metalRoadLabels.tile.getModelMatrix(mapZoomState: mapZoomState, pan: mapPanning)
            let meta                = roadLabels.mapLabelsCpuMeta
            var maxInstances        = 0
            //print("meta.count = ", meta.count)
            var lineToStartFloats           : [MapRoadLabelsAssembler.LineToStartAt] = []
            var startRoadLabelsAtFull       : [MapRoadLabelsAssembler.StartRoadAt] = []
            for roadLabelIndex in 0..<meta.count {
                let roadLabel           = meta[roadLabelIndex]
                let worldPathLen        = roadLabel.pathLen
                let measuredText        = roadLabel.measuredText
                let textScreenWidth     = measuredText.width * roadLabel.scale + Settings.roadLabelScreenSpacing
                let localPositions      = roadLabel.localPositions
                let count               = localPositions.count
                var screenPathLen       = Float(0);
                let glyphShifts         = roadLabel.glyphShifts
                
                var startRoadLabelsAt   : [MapRoadLabelsAssembler.StartRoadAt] = []
                
                // вычисляем длину кривой на экране
                for i in 0..<count-1 {
                    let currentScreen   = output[startRoadResultsIndex + i + outputIndexShift]
                    let nextScreen      = output[startRoadResultsIndex + i + outputIndexShift + 1]
                    let screenLen       = length(nextScreen - currentScreen)
                    screenPathLen       += screenLen
                }
            
                let factor                  = Float(0.5)
                var factors: [Float]        = [factor]
                var textStartScreenShift    = Float(0); // начинаем текст через эту длина на экранной кривой
                var worldPoint              = SIMD2<Float>(0, 0);
                var previousScreenLen       = Float(0);
                var worldTextCenter         = worldPathLen * factor;
                var textCenterScreenPoint   = SIMD2<Float>(0, 0);
                
                
                var startTextLocationIndex = Int(0)
                var inSegmentScreenLen = Float(0)
                
                // Вычисляем положение начала текста на экранной кривой по мировому центру текста
                for i in 0..<count-1 {
                    // Длина участка в мировых координатах
                    let current         = localPositions[i];
                    let next            = localPositions[i + 1];
                    let len             = length(next - current);

                    // Длина участка в экранных координатах
                    let currentScreen   = output[startRoadResultsIndex + i + outputIndexShift];
                    let nextScreen      = output[startRoadResultsIndex + i + outputIndexShift + 1];
                    let screenLen       = length(nextScreen - currentScreen);

                    // Проверяем нашли ли мы сегмент в котором расположен центр текста либо это уже последний сегмент
                    if worldTextCenter - len < 0 || i == count-2 {
                        startTextLocationIndex  = i
                        let inSegmentWorldLen   = worldTextCenter;
                        let direction           = normalize(next - current);
                        worldPoint              = current + direction * inSegmentWorldLen; // точка центра текста в мировых координатах
                        textCenterScreenPoint   = localTilePositionToScreenSpacePosition(modelMatrix: modelMatrix,
                                                                                         localPosition: worldPoint,
                                                                                         worldUniforms: uniforms);
                        
                        inSegmentScreenLen      = length(textCenterScreenPoint - currentScreen);
                        textStartScreenShift    = previousScreenLen + inSegmentScreenLen - textScreenWidth / 2;
                        // получили начало текста на экранной кривой
                        break;
                    }
                    worldTextCenter   -= len;
                    previousScreenLen += screenLen;
                }

                let textEndScreenShift = textStartScreenShift + textScreenWidth
                
                
                // Выходит за пределы доступного расстояния экранной кривой
                if 0 > textStartScreenShift || textEndScreenShift > screenPathLen {
                    factors = []
                }
                
                // выходит за пределы видимой экранной области
                if textCenterScreenPoint.x + textScreenWidth < 0 ||
                    textCenterScreenPoint.y + textScreenWidth < 0 ||
                    textCenterScreenPoint.x - textScreenWidth > viewportSize.x ||
                    textCenterScreenPoint.y - textScreenWidth > viewportSize.y {
                    factors = []
                }
                
                
                // Учитываем пересечения, коллизии
                if factors.isEmpty == false {
                    testPoints.append(textCenterScreenPoint)
                    
//                    let scale           = roadLabel.scale
//                    let textHeight      = abs(measuredText.top - measuredText.bottom);
//                    
//                    // TODO оптимизировать
//                    var shiftIndex                  = 0;
//                    var textStartScreenShiftTemp    = textStartScreenShift
//                    let screenCurrent               = output[startRoadResultsIndex + outputIndexShift];
//                    let screenNext                  = output[startRoadResultsIndex + outputIndexShift + 1];
//                    var len                         = length(screenNext - screenCurrent);
//                    
//                    //textStartScreenShiftTemp += glyphShift * scale;
//                    
//                    while (textStartScreenShiftTemp > len && count - 1 > shiftIndex) {
//                        textStartScreenShiftTemp -= len;
//                        shiftIndex += 1;
//                        let screenCurrent   = output[startRoadResultsIndex + outputIndexShift + shiftIndex];
//                        let screenNext      = output[startRoadResultsIndex + outputIndexShift + 1 + shiftIndex];
//                        len = length(screenNext - screenCurrent);
//                    }
//                    
//                    let direction = normalize(screenNext - screenCurrent);
//                    let vertexPos = screenCurrent + direction * textStartScreenShiftTemp;
//                    testPoints.append(vertexPos)
                }
                
                
                // сдвигаемся в массиве результатов экранных координат чтобы обработать следующую дорожную улицу
                outputIndexShift += count
                
                // обновляем количество инстансов для дублирующего рендринга улицы
                if factors.count > maxInstances {
                    maxInstances = factors.count
                }
                
                for factor in factors {
                    startRoadLabelsAt.append(MapRoadLabelsAssembler.StartRoadAt(startAt: factor))
                }
                
                lineToStartFloats.append(MapRoadLabelsAssembler.LineToStartAt(index: simd_int1(startRoadLabelsAtFull.count),
                                                                              count: simd_int1(startRoadLabelsAt.count)))
                startRoadLabelsAtFull.append(contentsOf: startRoadLabelsAt)
            }
            
            renderingCurrentRoadLabels.append(DrawTileRoadLabelsPrep(lineToStartAt: lineToStartFloats,
                                                                         startAt: startRoadLabelsAtFull,
                                                                         metalRoadLabels: metalRoadLabels,
                                                                         maxInstances: maxInstances))
        }
        
        self.currentRenderingRoads = RenderingRoadLabelsTB(tilesPrepare: renderingCurrentRoadLabels,
                                                    bufferingCounter: Settings.maxBuffersInFlight)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let time = endTime - startTime
        //print(time)
    }
    
    func evaluate(lastUniforms: Uniforms, mapPanning: SIMD3<Double>) -> Bool {
        let result = handleGeoLabels.forEvaluateCollisions(mapPanning: mapPanning)
        if result.recallLater {
            return true
        }
        
        var forCompute: [ComputeScreenPositions.Vertex] = []
        
        // создать массив для рассчета экранных точек
        for i in 0..<roadLabelsByTiles.count {
            let roadLabelsOfTile    = roadLabelsByTiles[i]
            guard let roadLabels    = roadLabelsOfTile.roadLabels else { continue }
            for meta in roadLabels.mapLabelsCpuMeta {
                let computeInput    = meta.localPositions.map { localPoint in ComputeScreenPositions.Vertex(location: localPoint,
                                                                                                            matrixId: simd_short1(i)) }
                forCompute.append(contentsOf: computeInput)
            }
        }
        
        var inputComputeScreenVertices      = result.inputComputeScreenVertices
        let startRoadResultsIndex           = inputComputeScreenVertices.count
        
        inputComputeScreenVertices.append(contentsOf: forCompute)
        
        projectPoints.project(input: CombinedCompSP.Input(modelMatrices: result.modelMatrices,
                                                          uniforms: lastUniforms,
                                                          mapPanning: mapPanning,
                                                          inputComputeScreenVertices: inputComputeScreenVertices,
                                                          
                                                          metalGeoLabels: result.metalGeoLabels,
                                                          mapLabelLineCollisionsMeta: result.mapLabelLineCollisionsMeta,
                                                          actualLabelsIds: handleGeoLabels.actualLabelsIds,
                                                          geoLabelsSize: result.geoLabelsSize,
                                                          
                                                          startRoadResultsIndex: startRoadResultsIndex,
                                                          roadLabels: roadLabelsByTiles))
        
        return false
    }
}
