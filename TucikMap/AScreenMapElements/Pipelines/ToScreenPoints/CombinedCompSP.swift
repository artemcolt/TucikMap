//
//  ProjectPoints.swift
//  TucikMap
//
//  Created by Artem on 7/12/25.
//

import MetalKit

// Combined Compute Screen Positions
// Считает координаты экранной проекции. Так же как ComputeScreenPositions считает экранные координаты, но в контексте карты
// После рассчета экранных координат требуется продолжить выполнять следующий код для финального отображения данных на экране, отрисовки данных
//
class CombinedCompSP {
    
    // Данные с предыдущего этапа, используем их в рассчетах после получения экранных координат
    struct Input {
        let uniforms                        : Uniforms
        let inputComputeScreenVertices      : [ComputeScreenPositions.Vertex]
        
        // Сохраняем данные испольуемые в рассчетах чтобы после получения экранных координат с GPU продолжить работу
        // mapLabelLineCollisionsMeta - данные для использования на CPU
        // metalGeoLabels - страны, города, континенты, моря
        // actualLabelsIds - метки которые на жанной стадии должны быть отображены
        // есть еще не актуальные, это те которые использовались до этого, они нужны временно чтобы например анимация до конца отработала
        let metalGeoLabels                  : [MetalTile.TextLabels]
        let mapLabelLineCollisionsMeta      : [MapLabelsAssembler.MapLabelCpuMeta]
        let actualLabelsIds                 : Set<UInt>
        let geoLabelsSize                   : Int
    }
    
    
    fileprivate let metalCommandQueue               : MTLCommandQueue
    fileprivate let uniformBuffer                   : MTLBuffer
    fileprivate let inputScreenPositionsBuffer      : MTLBuffer
    fileprivate let mapSettings                     : MapSettings
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         mapSettings: MapSettings) {
        self.mapSettings                    = mapSettings
        self.metalCommandQueue              = metalCommandQueue
        
        let inputBufferWorldPostionsSize    = mapSettings.getMapCommonSettings().getMaxInputComputeScreenPoints()
        
        // Этим значением заполним буффер входных вертексов
        var inputScreenPositionsMock        = Array(repeating: ComputeScreenPositions.Vertex(location: SIMD2<Float>(), matrixId: 0),
                                                    count: inputBufferWorldPostionsSize)
        
        
        uniformBuffer                       = metalDevice.makeBuffer(length: MemoryLayout<Uniforms>.stride)!
        inputScreenPositionsBuffer          = metalDevice.makeBuffer(bytes: &inputScreenPositionsMock,
                                                                     length: MemoryLayout<ComputeScreenPositions.Vertex>.stride * inputBufferWorldPostionsSize)!
    }
}




class CombinedCompSPGlobe: CombinedCompSP {
    struct InputGlobe {
        let input                           : Input
        let parameters                      : [DrawGlobeLabels.GlobeLabelsParams]
        let latitude                        : Float
        let longitude                       : Float
        let globeRadius                     : Float
        let transition                      : Float
        let planeNormal                     : SIMD3<Float>
    }
    
    // Результат работы класса для дальнейших вычислений
    struct ResultGlobe {
        let output                          : [ComputeScreenPositionsGlobe.GlobeComputeScreenOutput]
        let uniforms                        : Uniforms
        
        let metalGeoLabels                  : [MetalTile.TextLabels]
        let mapLabelLineCollisionsMeta      : [MapLabelsAssembler.MapLabelCpuMeta]
        let actualLabelsIds                 : Set<UInt>
        let geoLabelsSize                   : Int
    }
    
    fileprivate let inputParametersBuffer           : MTLBuffer
    fileprivate let outputWorldPositionsBuffer      : MTLBuffer
    fileprivate let onPointsReadyGlobe              : OnPointsReadyHandlerGlobe
    fileprivate var computeScreenPositionsGlobe     : ComputeScreenPositionsGlobe
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         onPointsReadyGlobe: OnPointsReadyHandlerGlobe,
         computeScreenPositionsGlobe: ComputeScreenPositionsGlobe,
         mapSettings: MapSettings) {
        self.onPointsReadyGlobe = onPointsReadyGlobe
        self.computeScreenPositionsGlobe = computeScreenPositionsGlobe
        
        // На каждый тайл есть парметры для того чтобы считать лейблы
        let parametersBufferSize            = mapSettings.getMapCommonSettings().getGeoLabelsParametersBufferSize()
        var inputParameters                 = Array(repeating: DrawGlobeLabels.GlobeLabelsParams(centerX: 0, centerY: 0, factor: 0),
                                                    count: parametersBufferSize)
        
        self.inputParametersBuffer          = metalDevice.makeBuffer(bytes: &inputParameters,
                                                                     length: MemoryLayout<DrawGlobeLabels.GlobeLabelsParams>.stride * parametersBufferSize)!
        
        let inputBufferWorldPostionsSize    = mapSettings.getMapCommonSettings().getMaxInputComputeScreenPoints()
        
        // в буфере храняться точки в экранной проекции
        // результат работы вычислительного шейдера
        let memLen = MemoryLayout<ComputeScreenPositionsGlobe.GlobeComputeScreenOutput>.stride
        self.outputWorldPositionsBuffer = metalDevice.makeBuffer(length: memLen * inputBufferWorldPostionsSize)!
        
        super.init(metalDevice: metalDevice, metalCommandQueue: metalCommandQueue, mapSettings: mapSettings)
    }
    
    func projectGlobe(inputGlobe: InputGlobe) {
        let inputBufferWorldPostionsSize    = mapSettings.getMapCommonSettings().getMaxInputComputeScreenPoints()
        var parameters                      = inputGlobe.parameters
        
        inputParametersBuffer.contents().copyMemory(from: &parameters,
                                                    byteCount: MemoryLayout<DrawGlobeLabels.GlobeLabelsParams>.stride * parameters.count)
        
        // проецируем из мировых координат в координаты экрана
        // для этого нужен тайл чтобы матрицу трансформации сделать в мировые координаты из локальных координат тайла
        let input               = inputGlobe.input
        let latitude            = inputGlobe.latitude
        let longitude           = inputGlobe.longitude
        let globeRadius         = inputGlobe.globeRadius
        let transition          = inputGlobe.transition
        let planeNormal         = inputGlobe.planeNormal
        let onPointsReadyGlobe  = onPointsReadyGlobe
        
        var uniforms                        = input.uniforms
        var inputComputeScreenVertices      = input.inputComputeScreenVertices
        let metalGeoLabels                  = input.metalGeoLabels
        let mapLabelLineCollisionsMeta      = input.mapLabelLineCollisionsMeta
        let actualLabelsIds                 = input.actualLabelsIds
        let geoLabelsSize                   = input.geoLabelsSize
        
        
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
        
        inputScreenPositionsBuffer.contents().copyMemory(from: &inputComputeScreenVertices,
                                                         byteCount: MemoryLayout<ComputeScreenPositions.Vertex>.stride * inputComputeScreenVertices.count)
        
        guard let commandBuffer             = metalCommandQueue.makeCommandBuffer(),
              let computeCommandEncoder     = commandBuffer.makeComputeCommandEncoder() else { return }
        
        
        let globeParams                     = DrawGlobeLabels.GlobeParams(latitude: latitude,
                                                                          longitude: longitude,
                                                                          globeRadius: globeRadius,
                                                                          transition: transition,
                                                                          planeNormal: planeNormal)
        let calculationBlockGlobe           = ComputeScreenPositionsGlobe.CalculationBlockGlobe(inputParametersBuffer: inputParametersBuffer,
                                                                                                inputBuffer: inputScreenPositionsBuffer,
                                                                                                outputBuffer: outputWorldPositionsBuffer,
                                                                                                vertexCount: inputBufferWorldPostionsSize,
                                                                                                readVerticesCount: inputComputeScreenVertices.count,
                                                                                                globeParams: globeParams)
        
        computeScreenPositionsGlobe.computeGlobe(uniforms: uniformBuffer,
                                                 computeEncoder: computeCommandEncoder,
                                                 calculationBlockGlobe: calculationBlockGlobe)
        
        computeCommandEncoder.endEncoding()
        commandBuffer.addCompletedHandler { buffer in
            DispatchQueue.main.async {
                // Вычислили экранные координаты на gpu
                let output = calculationBlockGlobe.readOutput()
                
                let result = ResultGlobe(output: output,
                                         uniforms: uniforms,
                                         metalGeoLabels: metalGeoLabels,
                                         mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
                                         actualLabelsIds: actualLabelsIds,
                                         geoLabelsSize: geoLabelsSize)
                
                onPointsReadyGlobe.onPointsReadyGlobe(resultGlobe: result)
            }
        }
        commandBuffer.commit()
    }
}




class CombinedCompSPFlat: CombinedCompSP {
    struct InputFlat {
        let input                           : Input
        let modelMatrices                   : [matrix_float4x4]
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
        let viewportSize                    : SIMD2<Float>
        
        // startRoadResultsIndex - данные о дорогах начинаются с этого индекса в output
        let startRoadResultsIndex           : Int
        let roadLabels                      : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    // Результат работы класса для дальнейших вычислений
    struct Result {
        let output                          : [SIMD2<Float>]
        let uniforms                        : Uniforms
        
        let metalGeoLabels                  : [MetalTile.TextLabels]
        let mapLabelLineCollisionsMeta      : [MapLabelsAssembler.MapLabelCpuMeta]
        let actualLabelsIds                 : Set<UInt>
        let geoLabelsSize                   : Int
    }
    
    struct ResultFlat {
        let result                          : Result
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
        let viewportSize                    : SIMD2<Float>
        
        let startRoadResultsIndex           : Int
        let metalRoadLabelsTiles            : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    fileprivate let inputParametersBuffer           : MTLBuffer
    fileprivate let outputWorldPositionsBuffer      : MTLBuffer
    fileprivate let onPointsReadyFlat               : OnPointsReadyHandlerFlat
    fileprivate let computeScreenPositionsFlat      : ComputeScreenPositionsFlat
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         onPointsReadyFlat: OnPointsReadyHandlerFlat,
         computeScreenPositionsFlat: ComputeScreenPositionsFlat, mapSettings: MapSettings) {
        self.onPointsReadyFlat = onPointsReadyFlat
        self.computeScreenPositionsFlat = computeScreenPositionsFlat
        
        // На каждый тайл есть парметры для того чтобы считать лейблы
        // В случае с flat представлением это модельная матрица для преобразования
        let parametersBufferSize            = mapSettings.getMapCommonSettings().getGeoLabelsParametersBufferSize()
        var inputModelMatrices              = Array(repeating: matrix_identity_float4x4, count: parametersBufferSize)
        self.inputParametersBuffer          = metalDevice.makeBuffer(bytes: &inputModelMatrices,
                                                                     length: MemoryLayout<matrix_float4x4>.stride * parametersBufferSize)!
        
        let inputBufferWorldPostionsSize    = mapSettings.getMapCommonSettings().getMaxInputComputeScreenPoints()
        
        // в буфере храняться точки в экранной проекции
        // результат работы вычислительного шейдера
        let memLen = MemoryLayout<SIMD2<Float>>.stride
        self.outputWorldPositionsBuffer = metalDevice.makeBuffer(length: memLen * inputBufferWorldPostionsSize)!
        
        super.init(metalDevice: metalDevice, metalCommandQueue: metalCommandQueue, mapSettings: mapSettings)
    }
    
    func projectFlat(inputFlat: InputFlat) {
        var modelMatrices = inputFlat.modelMatrices
        
        // для вызова заполянем текущие буффера в GPU
        // и вызывваем на GPU рассчет
        inputParametersBuffer.contents().copyMemory(from: &modelMatrices,
                                                    byteCount: MemoryLayout<matrix_float4x4>.stride * modelMatrices.count)
        
        // проецируем из мировых координат в координаты экрана
        // для этого нужен тайл чтобы матрицу трансформации сделать в мировые координаты из локальных координат тайла
        let input                           = inputFlat.input
        let mapPanning                      = inputFlat.mapPanning
        let mapSize                         = inputFlat.mapSize
        let viewportSize                    = inputFlat.viewportSize
        let startRoadResultsIndex           = inputFlat.startRoadResultsIndex
        let metalRoadLabelsTiles            = inputFlat.roadLabels
        let actualRoadLabelsIds             = inputFlat.actualRoadLabelsIds
        let onPointsReadyFlat               = onPointsReadyFlat
        
        var uniforms                        = input.uniforms
        var inputComputeScreenVertices      = input.inputComputeScreenVertices
        let metalGeoLabels                  = input.metalGeoLabels
        let mapLabelLineCollisionsMeta      = input.mapLabelLineCollisionsMeta
        let actualLabelsIds                 = input.actualLabelsIds
        let geoLabelsSize                   = input.geoLabelsSize
        
        
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
        
        inputScreenPositionsBuffer.contents().copyMemory(from: &inputComputeScreenVertices,
                                                         byteCount: MemoryLayout<ComputeScreenPositions.Vertex>.stride * inputComputeScreenVertices.count)
        
        guard let commandBuffer             = metalCommandQueue.makeCommandBuffer(),
              let computeCommandEncoder     = commandBuffer.makeComputeCommandEncoder() else { return }
        
        
        let inputBufferWorldPostionsSize    = mapSettings.getMapCommonSettings().getMaxInputComputeScreenPoints()
        let calculationBlock                = ComputeScreenPositionsFlat.CalculationBlock(inputParametersBuffer: inputParametersBuffer,
                                                                                          inputBuffer: inputScreenPositionsBuffer,
                                                                                          outputBuffer: outputWorldPositionsBuffer,
                                                                                          vertexCount: inputBufferWorldPostionsSize,
                                                                                          readVerticesCount: inputComputeScreenVertices.count)
        
        
        computeScreenPositionsFlat.computeFlat(uniforms: uniformBuffer,
                                               computeEncoder: computeCommandEncoder,
                                               calculationBlock: calculationBlock)
                                              
        
        computeCommandEncoder.endEncoding()
        commandBuffer.addCompletedHandler { buffer in
            DispatchQueue.main.async {
                // Вычислили экранные координаты на gpu
                let output  = calculationBlock.readOutput()
                
                let result = Result(output: output,
                                    uniforms: uniforms,
                                    metalGeoLabels: metalGeoLabels,
                                    mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
                                    actualLabelsIds: actualLabelsIds,
                                    geoLabelsSize: geoLabelsSize)
                
                let resultFlat = ResultFlat(result: result,
                                            mapPanning: mapPanning,
                                            mapSize: mapSize,
                                            viewportSize: viewportSize,
                                            startRoadResultsIndex: startRoadResultsIndex,
                                            metalRoadLabelsTiles: metalRoadLabelsTiles,
                                            actualRoadLabelsIds: actualRoadLabelsIds)
                
                onPointsReadyFlat.onPointsReadyFlat(resultFlat: resultFlat)
            }
        }
        commandBuffer.commit()
    }
}
