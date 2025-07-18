//
//  ComputeScreenPositions.swift
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

import MetalKit

// Переводит в координаты экрана из мировых координат умноженных на матрицу модели
// на выходе получается массив из координат в экранном пространстве
// рассчет происходит на gpu
// рассчитывает экранные координаты для размещения информационного текста на карте
class ComputeScreenPositions {
    let metalDevice             : MTLDevice
    let computeScreenPipeline   : ComputeScreenPipeline // Пайплайн для отправки данных на gpu для параллельного рассчета
    
    let threadsPerGroup = MTLSize(
        width:  32,
        height: 1,
        depth:  1
    )
    
    // GPU обрабатывает эту структуру
    // Использует матрицу модели потому что тайлы содержат локальные координаты и чтобы получить мировые их нужно умножить на матрицу модели
    // Эта матрица рассчитывается на основе mapPanning, зума и самого тайла
    struct Vertex {
        let location: SIMD2<Float> // точка в мировых координатах
        let matrixId: simd_short1  // индекс матрицы модели чтобы преобразовать окончательно мировую точку
    }
    
    // Содержит все данные для рассчета и получения результата
    struct CalculationBlock {
        let inputModelMatricesBuffer        : MTLBuffer
        let inputBuffer                     : MTLBuffer
        let outputBuffer                    : MTLBuffer
        let vertexCount                     : Int // полный размер выделенного буффера
        let readVerticesCount               : Int // сколько в inputBuffer записали вертексов сттолько и нужно прочитать на выходе
        
        func readOutput() -> [SIMD2<Float>] {
            let outputPtr = outputBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: readVerticesCount)
            let output = Array(UnsafeBufferPointer(start: outputPtr, count: readVerticesCount))
            return output
        }
    }
    
    init(metalDevice: MTLDevice, library: MTLLibrary) {
        self.metalDevice        = metalDevice
        computeScreenPipeline   = ComputeScreenPipeline(metalDevice: metalDevice, library: library)
    }
    
    // uniforms - текущее состояние камеры, экранная проекция считается в зависимости от текущей видимой области
    // calculationBlock - входные данные для рассчета и отсюда же брать результаты
    func compute(
        uniforms                                : MTLBuffer,
        computeEncoder                          : MTLComputeCommandEncoder,
        calculationBlock                        : CalculationBlock,
    ) {
        computeScreenPipeline.selectComputePipeline(computeEncoder: computeEncoder)
        let inputBuffer                     = calculationBlock.inputBuffer
        let outputBuffer                    = calculationBlock.outputBuffer
        let vertexCount                     = calculationBlock.vertexCount
        let inputModelMatricesBuffer        = calculationBlock.inputModelMatricesBuffer
        
        computeEncoder.setBuffer(inputBuffer,               offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer,              offset: 0, index: 1)
        computeEncoder.setBuffer(uniforms,                  offset: 0, index: 2)
        computeEncoder.setBuffer(inputModelMatricesBuffer,  offset: 0, index: 3)
        
        let threadGroupsWidth = (vertexCount + threadsPerGroup.width - 1) / threadsPerGroup.width
        let threadGroups      = MTLSize(width: threadGroupsWidth, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
    }
}
