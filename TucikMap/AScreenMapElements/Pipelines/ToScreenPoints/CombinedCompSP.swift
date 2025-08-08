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
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
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
        
        // startRoadResultsIndex - данные о дорогах начинаются с этого индекса в output
        let startRoadResultsIndex           : Int
        let roadLabels                      : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    struct InputFlat {
        let input                           : Input
        let modelMatrices                   : [matrix_float4x4]
    }
    
    struct InputGlobe {
        let input                           : Input
        let parameters                      : [CompScreenGlobePipe.Parmeters]
    }
    
    // Результат работы класса для дальнейших вычислений
    struct Result {
        let output                          : [SIMD2<Float>]
        
        let uniforms                        : Uniforms
        let mapPanning                      : SIMD3<Double>
        let mapSize                         : Float
        
        let metalGeoLabels                  : [MetalTile.TextLabels]
        let mapLabelLineCollisionsMeta      : [MapLabelsAssembler.MapLabelCpuMeta]
        let actualLabelsIds                 : Set<UInt>
        let geoLabelsSize                   : Int
        
        let startRoadResultsIndex           : Int
        let metalRoadLabelsTiles            : [MetalTile.RoadLabels]
        let actualRoadLabelsIds             : Set<UInt>
    }
    
    private let computeScreenPositions          : ComputeScreenPositions // переводит из мировых в координаты экрана
    private let metalCommandQueue               : MTLCommandQueue
    
    private let uniformBuffer                   : MTLBuffer
    private let inputParametersBuffer           : MTLBuffer
    private let inputScreenPositionsBuffer      : MTLBuffer
    private let outputWorldPositionsBuffer      : MTLBuffer
    private let onPointsReady                   : (Result) -> Void
    
    // размер для входного буффера точек, максимально может быть столько точек
    private let inputBufferWorldPostionsSize    = Settings.maxInputComputeScreenPoints
    // размер для входного буффера матриц, макисмально может быть столько матриц
    private let modelMatrixBufferSize           = Settings.geoLabelsParametersBufferSize
    
    init(
        computeScreenPositions: ComputeScreenPositions,
        metalDevice: MTLDevice,
        metalCommandQueue: MTLCommandQueue,
        onPointsReady: @escaping (Result) -> Void
    ) {
        self.onPointsReady              = onPointsReady
        self.computeScreenPositions     = computeScreenPositions
        self.metalCommandQueue          = metalCommandQueue
        
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
    
    func projectFlat(inputFlat: InputFlat) {
        var modelMatrices = inputFlat.modelMatrices
        
        // для вызова заполянем текущие буффера в GPU
        // и вызывваем на GPU рассчет
        inputParametersBuffer.contents().copyMemory(from: &modelMatrices,
                                                    byteCount: MemoryLayout<matrix_float4x4>.stride * modelMatrices.count)
        
        project(input: inputFlat.input, mapMode: .flat)
    }
    
    func projectGlobe(inputGlobe: InputGlobe) {
        var parameters = inputGlobe.parameters
        
        inputParametersBuffer.contents().copyMemory(from: &parameters,
                                                    byteCount: MemoryLayout<CompScreenGlobePipe.Parmeters>.stride * parameters.count)
        
        project(input: inputGlobe.input, mapMode: .globe)
    }
    
    func project(input: Input, mapMode: MapMode) {
        // проецируем из мировых координат в координаты экрана
        // для этого нужен тайл чтобы матрицу трансформации сделать в мировые координаты из локальных координат тайла
        var uniforms                        = input.uniforms
        var inputComputeScreenVertices      = input.inputComputeScreenVertices
        let mapPanning                      = input.mapPanning
        let mapSize                         = input.mapSize
        let metalGeoLabels                  = input.metalGeoLabels
        let mapLabelLineCollisionsMeta      = input.mapLabelLineCollisionsMeta
        let startRoadResultsIndex           = input.startRoadResultsIndex
        let roadLabels                      = input.roadLabels
        let actualLabelsIds                 = input.actualLabelsIds
        let geoLabelsSize                   = input.geoLabelsSize
        let actualRoadLabelIds              = input.actualRoadLabelsIds
        
        
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
                                       calculationBlock: calculationBlock,
                                       mode: mapMode)
            
        
        computeCommandEncoder.endEncoding()
        commandBuffer.addCompletedHandler { buffer in
            DispatchQueue.main.async {
                // Вычислили экранные координаты на gpu
                let output  = calculationBlock.readOutput()
                let result  = Result(output: output,
                                     uniforms: uniforms,
                                     mapPanning: mapPanning,
                                     mapSize: mapSize,
                                     
                                     metalGeoLabels: metalGeoLabels,
                                     mapLabelLineCollisionsMeta: mapLabelLineCollisionsMeta,
                                     actualLabelsIds: actualLabelsIds,
                                     geoLabelsSize: geoLabelsSize,
                                     
                                     startRoadResultsIndex: startRoadResultsIndex,
                                     metalRoadLabelsTiles: roadLabels,
                                     actualRoadLabelsIds: actualRoadLabelIds
                )
                
                self.onPointsReady(result)
            }
        }
        commandBuffer.commit()
    }
}
