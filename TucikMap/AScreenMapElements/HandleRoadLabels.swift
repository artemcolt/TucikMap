//
//  HandleRoadLabels.swift
//  TucikMap
//
//  Created by Artem on 7/20/25.
//

import MetalKit


class HandleRoadLabels {
    struct OnPointsReady {
        let output                          : [SIMD2<Float>]
        let uniforms                        : Uniforms
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
        
        let startRoadResultsIndex           : Int
        let metalRoadLabelsTiles            : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    private let mapZoomState        : MapZoomState
    private let frameCounter        : FrameCounter
    private let mapSettings         : MapSettings
    private var roadLabelsByTiles   : [MetalTile.RoadLabels] = []
    
    private var savedLabelIntersections: [UInt: LabelIntersection] = [:]
    var actualLabelsIds: Set<UInt> = []
    
    init(mapZoomState: MapZoomState, frameCounter: FrameCounter, mapSettings: MapSettings) {
        self.mapSettings    = mapSettings
        self.mapZoomState   = mapZoomState
        self.frameCounter   = frameCounter
    }
    
    private var currentRenderingRoads: RenderingRoadLabelsTB = RenderingRoadLabelsTB(tilesPrepare: [], bufferingCounter: 0)
    func getRoadLabels() -> RenderingRoadLabelsTB? {
        // чтобы постоянно не перезаписывать буффера пересечений
        // запись будет только в первые 3 кадра для тройной буферизации, а дальше использование свежих буфферов
        if currentRenderingRoads.bufferingCounter <= 0 { return nil }
        
        currentRenderingRoads.bufferingCounter -= 1
        return currentRenderingRoads
    }
    
    func setRoadLabels(roadLabels: [MetalTile.RoadLabels]) {
        guard roadLabels.isEmpty == false else { return }
        let elapsedTime = frameCounter.getElapsedTimeSeconds()
        
        let currentZ = roadLabels.first!.tile.z
        var savePrevious: [MetalTile.RoadLabels] = []
        for i in 0..<roadLabelsByTiles.count {
            var label = roadLabelsByTiles[i]
            let isDifferentZ = label.tile.z != currentZ
            if isDifferentZ {
                label.timePoint = elapsedTime
                savePrevious.append(label)
            }
        }
        
        // ресетит тайлы, делает их снова актуальными
        var roadLabels = roadLabels
        for i in 0..<roadLabels.count {
            roadLabels[i].timePoint = nil
        }
        self.actualLabelsIds = Set(roadLabels.flatMap { label in label.containIds })
        self.roadLabelsByTiles = roadLabels + savePrevious
    }
    
    func forEvaluateCollisions(pipeline: inout ScreenCollisionsDetector.ForEvaluationResult,
                               prepareToScreenData: PrepareToScreenData
    ) {
        let labelsFadeAnimationTimeSeconds = mapSettings.getMapCommonSettings().getLabelsFadeAnimationTimeSeconds()
        let printRoadLabelsCount = mapSettings.getMapDebugSettings().getPrintRoadLabelsCount()
        
        // Удаляет стухшие тайлы с дорожными метками
        let elapsedTime = self.frameCounter.getElapsedTimeSeconds()
        var metalRoadLabels: [MetalTile.RoadLabels] = []
        for roadLabel in self.roadLabelsByTiles {
            if roadLabel.timePoint == nil || elapsedTime - roadLabel.timePoint! < labelsFadeAnimationTimeSeconds {
                metalRoadLabels.append(roadLabel)
            }
        }
        self.roadLabelsByTiles = metalRoadLabels
        
        
        // создать массив для рассчета экранных точек
        var roadLabelsCount = 0
        var forCompute: [ComputeScreenPositions.Vertex] = []
        for i in 0..<roadLabelsByTiles.count {
            let roadLabelsOfTile    = roadLabelsByTiles[i]
            guard let roadLabels    = roadLabelsOfTile.roadLabels else { continue }
            
            let matrixIndex         = prepareToScreenData.getForScreenDataIndex(tile: roadLabelsOfTile.tile)
            for meta in roadLabels.mapLabelsCpuMeta {
                roadLabelsCount += 1
                let computeInput = meta.localPositions.map { localPoint in ComputeScreenPositions.Vertex(location: localPoint,
                                                                                                         matrixId: simd_int1(matrixIndex)) }
                forCompute.append(contentsOf: computeInput)
            }
        }
        
        if printRoadLabelsCount {
            print("Road labels count = ", roadLabelsCount)
        }
        
        let startRoadResultsIndex           = pipeline.inputComputeScreenVertices.count
        pipeline.startRoadResultsIndex      = startRoadResultsIndex
        pipeline.metalRoadLabels            = roadLabelsByTiles
        pipeline.inputComputeScreenVertices.append(contentsOf: forCompute)
    }
    
    func onPointsReady(result: OnPointsReady, spaceIntersections: SpaceIntersectionsProtocol, viewportSize: SIMD2<Float>) {
        let uniforms                    = result.uniforms
        let mapPanning                  = result.mapPanning
        let mapSize                     = result.mapSize
        let output                      = result.output
        let startRoadResultsIndex       = result.startRoadResultsIndex
        let metalRoadLabelsTiles        = result.metalRoadLabelsTiles // по тайлам метки дорог
        var outputIndexShift            = 0
        let elapsedTime                 = frameCounter.getElapsedTimeSeconds()
        let actualRoadLabelsIdsCaching  = result.actualRoadLabelsIds
        let roadLabelScreenSpacing      = mapSettings.getMapCommonSettings().getRoadLabelScreenSpacing()
        
        var renderingCurrentRoadLabels  : [DrawTileRoadLabelsPrep] = []
        
        //print("--------------------")
        for metalRoadLabels in metalRoadLabelsTiles {
            guard let roadLabels    = metalRoadLabels.roadLabels else { continue }
            let modelMatrix         = metalRoadLabels.tile.getModelMatrix(mapZoomState: mapZoomState, pan: mapPanning, mapSize: mapSize)
            let meta                = roadLabels.mapLabelsCpuMeta
            var maxInstances        = 0
            let labelsCount         = meta.count
            var labelIntersections  = [LabelIntersection] (repeating: LabelIntersection(hide: false, createdTime: 0), count: labelsCount)
            
            //print("meta.count = ", meta.count)
            var lineToStartFloats           : [MapRoadLabelsAssembler.LineToStartAt] = []
            var startRoadLabelsAtFull       : [MapRoadLabelsAssembler.StartRoadAt] = []
            for roadLabelIndex in 0..<labelsCount {
                let roadLabel           = meta[roadLabelIndex]
                let worldPathLen        = roadLabel.pathLen
                let measuredText        = roadLabel.measuredText
                let textScreenWidth     = measuredText.width * roadLabel.scale + roadLabelScreenSpacing
                let localPositions      = roadLabel.localPositions
                let count               = localPositions.count
                var screenPathLen       = Float(0);
                let glyphShifts         = roadLabel.glyphShifts
                let scale               = roadLabel.scale
                let labelId             = roadLabel.id
                var show                = true
                
                
                // вычисляем длину кривой на экране
                for i in 0..<count-1 {
                    let currentScreen   = output[startRoadResultsIndex + i + outputIndexShift]
                    let nextScreen      = output[startRoadResultsIndex + i + outputIndexShift + 1]
                    let screenLen       = length(nextScreen - currentScreen)
                    screenPathLen       += screenLen
                }
            
                let factor                  = Float(0.5)
                let factors: [Float]        = [factor]
                var textStartScreenShift    = Float(0); // начинаем текст через эту длина на экранной кривой
                var worldPoint              = SIMD2<Float>(0, 0);
                var previousScreenLen       = Float(0);
                var worldTextCenter         = worldPathLen * factor;
                var textCenterScreenPoint   = SIMD2<Float>(0, 0);
                var inSegmentScreenLen      = Float(0)
                
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
                    //factors = []
                    show = false
                }
                
                // выходит за пределы видимой экранной области
                if textCenterScreenPoint.x + textScreenWidth < 0 ||
                    textCenterScreenPoint.y + textScreenWidth < 0 ||
                    textCenterScreenPoint.x - textScreenWidth > viewportSize.x ||
                    textCenterScreenPoint.y - textScreenWidth > viewportSize.y {
                    //factors = []
                    show = false
                }
                
                
                // Учитываем пересечения, коллизии
                if factors.isEmpty == false {
                    // TODO оптимизировать
                    var shapes: [Shape] = []
                    shapes.reserveCapacity(glyphShifts.count)
                    for glyphShift in glyphShifts {
                        var startScreen = textStartScreenShift + glyphShift * scale
                        for i in 0..<count-1 {
                            let screenCurrent = output[startRoadResultsIndex + i + outputIndexShift]
                            let screenNext = output[startRoadResultsIndex + i + outputIndexShift + 1]
                            let len = length(screenNext - screenCurrent)
                            if startScreen - len < 0 {
                                let direction = normalize(screenNext - screenCurrent)
                                let screenPoint = screenCurrent + direction * startScreen
                                //testPoints.append(screenPoint + SIMD2<Float>(halfScale, halfScale))
                                let bound = LTRBBounds.from(location: screenPoint, height: scale, width: scale)
                                shapes.append(Shape.rect(bound))
                                break;
                            }
                            startScreen -= len
                        }
                    }
                    
                    
                    let contains = spaceIntersections.addAsSingle(shapes: shapes)
                    if contains == false {
                        //factors = []
                        show = false
                    }
                }
                
                
                let labelIntersection: LabelIntersection
                let isActualLabel = actualRoadLabelsIdsCaching.contains(labelId)
                if isActualLabel == false {
                    if let previousState = self.savedLabelIntersections[labelId] {
                        let isHideAlready = previousState.hide == true
                        let createdTime = isHideAlready ? previousState.createdTime : elapsedTime
                        labelIntersection = LabelIntersection(hide: true, createdTime: createdTime)
                    } else {
                        labelIntersection = LabelIntersection(hide: true, createdTime: elapsedTime)
                    }
                } else {
                    let hide = show == false
                    if let previousState = self.savedLabelIntersections[labelId] {
                        let statusChanged = hide != previousState.hide
                        let createdTime = statusChanged ? elapsedTime : previousState.createdTime
                        labelIntersection = LabelIntersection(hide: hide, createdTime: createdTime)
                    } else {
                        labelIntersection = LabelIntersection(hide: hide, createdTime: hide == true ? 0 : elapsedTime)
                    }
                }
                labelIntersections[roadLabelIndex] = labelIntersection
                self.savedLabelIntersections[labelId] = labelIntersection
                //print("hide = ", labelIntersection.hide)
                
                
                // сдвигаемся в массиве результатов экранных координат чтобы обработать следующую дорожную улицу
                outputIndexShift += count
                
                // обновляем количество инстансов для дублирующего рендринга улицы
                if factors.count > maxInstances {
                    maxInstances = factors.count
                }
                
                let startRoadLabelsAt: [MapRoadLabelsAssembler.StartRoadAt] = factors.map { factor in MapRoadLabelsAssembler.StartRoadAt(startAt: factor) }
                lineToStartFloats.append(MapRoadLabelsAssembler.LineToStartAt(index: simd_int1(startRoadLabelsAtFull.count),
                                                                              count: simd_int1(startRoadLabelsAt.count)))
                startRoadLabelsAtFull.append(contentsOf: startRoadLabelsAt)
            }
            
            renderingCurrentRoadLabels.append(DrawTileRoadLabelsPrep(lineToStartAt: lineToStartFloats,
                                                                     startAt: startRoadLabelsAtFull,
                                                                     labelIntersections: labelIntersections,
                                                                     metalRoadLabels: metalRoadLabels,
                                                                     maxInstances: maxInstances))
        }
        
        let maxBuffersInFlight = mapSettings.getMapCommonSettings().getMaxBuffersInFlight()
        self.currentRenderingRoads = RenderingRoadLabelsTB(tilesPrepare: renderingCurrentRoadLabels, bufferingCounter: maxBuffersInFlight)
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
}
