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
    
    // Результат работы класса для дальнейших вычислений
    struct Result {
        let output                          : [SIMD2<Float>]
        let uniforms                        : Uniforms
        
        let metalGeoLabels                  : [MetalTile.TextLabels]
        let mapLabelLineCollisionsMeta      : [MapLabelsAssembler.MapLabelCpuMeta]
        let actualLabelsIds                 : Set<UInt>
        let geoLabelsSize                   : Int
    }
    
    fileprivate let metalCommandQueue               : MTLCommandQueue
    fileprivate let uniformBuffer                   : MTLBuffer
    fileprivate let inputParametersBuffer           : MTLBuffer
    fileprivate let inputScreenPositionsBuffer      : MTLBuffer
    fileprivate let outputWorldPositionsBuffer      : MTLBuffer
    
    fileprivate var computeScreenPositions          : ComputeScreenPositions
    
    // размер для входного буффера точек, максимально может быть столько точек
    fileprivate let inputBufferWorldPostionsSize    = Settings.maxInputComputeScreenPoints
    // размер для входного буффера матриц, макисмально может быть столько матриц
    fileprivate let modelMatrixBufferSize           = Settings.geoLabelsParametersBufferSize
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         computeScreenPositions: ComputeScreenPositions) {
        self.metalCommandQueue          = metalCommandQueue
        self.computeScreenPositions     = computeScreenPositions
        
        // этим значением запоним буффер входных вертексов
        var inputScreenPositionsMock    = Array(repeating: ComputeScreenPositions.Vertex(location: SIMD2<Float>(), matrixId: 0),
                                                count: inputBufferWorldPostionsSize)
        
        
        uniformBuffer                   = metalDevice.makeBuffer(length: MemoryLayout<Uniforms>.stride)!
        inputScreenPositionsBuffer      = metalDevice.makeBuffer(bytes: &inputScreenPositionsMock,
                                                                 length: MemoryLayout<ComputeScreenPositions.Vertex>.stride * inputBufferWorldPostionsSize)!
        
        
        var inputModelMatrices          = Array(repeating: matrix_identity_float4x4, count: modelMatrixBufferSize)
        inputParametersBuffer        = metalDevice.makeBuffer(bytes: &inputModelMatrices,
                                                                 length: MemoryLayout<matrix_float4x4>.stride * modelMatrixBufferSize)!
        
        // в буфере храняться точки в экранной проекции
        // результат работы вычислительного шейдера
        outputWorldPositionsBuffer      = metalDevice.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * inputBufferWorldPostionsSize)!
    }
    
    fileprivate func _project(input: Input, handler: @escaping (_: Result) -> Void) {
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
        
        
        let calculationBlock                = ComputeScreenPositions.CalculationBlock(inputParametersBuffer: inputParametersBuffer,
                                                                                      inputBuffer: inputScreenPositionsBuffer,
                                                                                      outputBuffer: outputWorldPositionsBuffer,
                                                                                      vertexCount: inputBufferWorldPostionsSize,
                                                                                      readVerticesCount: inputComputeScreenVertices.count)
        
        
        computeScreenPositions.compute(uniforms: uniformBuffer,
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
                
                handler(result)
            }
        }
        commandBuffer.commit()
    }
}




class CombinedCompSPGlobe: CombinedCompSP {
    struct InputGlobe {
        let input                           : Input
        let parameters                      : [CompScreenGlobePipe.Parmeters]
    }
    
    struct ResultGlobe {
        let result                          : Result
    }
    
    fileprivate let onPointsReadyGlobe: OnPointsReadyHandlerGlobe
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         onPointsReadyGlobe: OnPointsReadyHandlerGlobe,
         computeScreenPositions: ComputeScreenPositions) {
        self.onPointsReadyGlobe = onPointsReadyGlobe
        super.init(metalDevice: metalDevice, metalCommandQueue: metalCommandQueue, computeScreenPositions: computeScreenPositions)
    }
    
    func projectGlobe(inputGlobe: InputGlobe) {
        var parameters = inputGlobe.parameters
        
        inputParametersBuffer.contents().copyMemory(from: &parameters,
                                                    byteCount: MemoryLayout<CompScreenGlobePipe.Parmeters>.stride * parameters.count)
        
        // проецируем из мировых координат в координаты экрана
        // для этого нужен тайл чтобы матрицу трансформации сделать в мировые координаты из локальных координат тайла
        let input               = inputGlobe.input
        let onPointsReadyGlobe  = onPointsReadyGlobe
        
        _project(input: input) { result in
            let resultGlobe = ResultGlobe(result: result)
            onPointsReadyGlobe.onPointsReadyGlobe(resultGlobe: resultGlobe)
        }
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
    
    struct ResultFlat {
        let result                          : Result
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
        let viewportSize                    : SIMD2<Float>
        
        let startRoadResultsIndex           : Int
        let metalRoadLabelsTiles            : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    fileprivate let onPointsReadyFlat: OnPointsReadyHandlerFlat
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         onPointsReadyFlat: OnPointsReadyHandlerFlat,
         computeScreenPositions: ComputeScreenPositions) {
        self.onPointsReadyFlat = onPointsReadyFlat
        super.init(metalDevice: metalDevice, metalCommandQueue: metalCommandQueue, computeScreenPositions: computeScreenPositions)
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
        
        _project(input: input) { result in
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
}
