//
//  TexturingTile.swift
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

import MetalKit

class GlobeTexturing {
    private let metalDevide         : MTLDevice
    private let metalCommandQueue   : MTLCommandQueue
    private let pipelines           : Pipelines
    private let drawTile            : DrawTile = DrawTile()
    private let uniformsBuffer      : MTLBuffer
    private let textureSize         : Int = Settings.globeTextureSize
    private var texturesBuffered    : [MTLTexture] = []
    
    func getTexture(frameBufferIndex: Int) -> MTLTexture {
        return texturesBuffered[frameBufferIndex]
    }
    
    init(metalDevide: MTLDevice, metalCommandQueue: MTLCommandQueue, pipelines: Pipelines) {
        self.metalDevide        = metalDevide
        self.metalCommandQueue  = metalCommandQueue
        self.pipelines          = pipelines
        
        let projectionMatrix    = MatrixUtils.orthographicMatrix(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
        var uniforms            = Uniforms(projectionMatrix: projectionMatrix,
                                           viewMatrix: matrix_identity_float4x4,
                                           viewportSize: SIMD2<Float>(0, 0),
                                           elapsedTimeSeconds: 0)
        
        uniformsBuffer          = metalDevide.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride)!
        
        let textureDescriptor   = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: textureSize,
                                                                         height: textureSize,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        
        texturesBuffered.reserveCapacity(Settings.maxBuffersInFlight)
        for _ in 0..<Settings.maxBuffersInFlight {
            let texture = metalDevide.makeTexture(descriptor: textureDescriptor)!
            texturesBuffered.append(texture)
        }
    }
    
    func render(currentFBIndex: Int,
                commandBuffer: MTLCommandBuffer,
                metalTiles: [MetalTile],
                areaRange: AreaRange) {
        
        let minTileX    = Float(areaRange.startX)
        let maxTileX    = Float(areaRange.endX)
        let minTileY    = Float(areaRange.minY)
        let maxTileY    = Float(areaRange.maxY)
        let currentZ    = Float(areaRange.z)
        let tilesNum    = pow(2, currentZ)
        
        let visXCenter  = minTileX + (maxTileX - minTileX) / 2
        let visYCenter  = minTileY + (maxTileY - minTileY) / 2
        
        let normalTileSize = Float(2.0)
        var windowSize = Float(3.0)
        switch currentZ {
            case 0: windowSize = 1
            case 1: windowSize = 2
            default: windowSize = 3
        }
        let windowTileFraction = Float(1) / windowSize
        
        let texture                 = texturesBuffered[currentFBIndex]
        let renderPassDescriptor    = MTLRenderPassDescriptor()
        
        // Указываем текстуру как цель рендеринга
        renderPassDescriptor.colorAttachments[0].texture    = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        pipelines.polygonPipeline.selectPipeline(renderEncoder: commandEncoder)
        drawTile.setUniforms(renderEncoder: commandEncoder, uniformsBuffer: uniformsBuffer)
        
        for looping in -1...1 {
            for metalTile in metalTiles {
                let tile = metalTile.tile
                let z = Float(tile.z)
                
                let relTile = tile.atDifferentZ(targetZ: Int(currentZ))
                let relX = relTile.x
                let relY = relTile.y
                
                let zDiff = currentZ - z
                let factor = pow(2, Float(zDiff)) // так же это относительный размер тайла
                let worldTileSize = Float(normalTileSize * windowTileFraction)
                
                // Чтобы на границе по x все правильно показывалось
                let loopingShift = Float(looping) * tilesNum
                
                let centerTileX = relX + factor / 2 - loopingShift
                let centerTileY = relY + factor / 2
                
                let difXFromCenter = visXCenter - centerTileX
                let difYFromCenter = visYCenter - centerTileY
                
                var relativeTileDeltaX = Float(0)
                var relativeTileDeltaY = Float(0)
                
                // при сетке из трех нужно отцентрировать
                // но в итоге работает на любой сетке
                relativeTileDeltaX -= 0.5
                relativeTileDeltaY += 0.5
                
                relativeTileDeltaX -= difXFromCenter
                relativeTileDeltaY += difYFromCenter
                
                // пропускаем то что в итоге не отображается в текстуре
                let leftTileBorder = relativeTileDeltaX - factor / 2
                let rightTileBorder = relativeTileDeltaX + factor / 2
                let relativeVisibleBorders = Float(windowSize / 2.0)
                let tooMuchLeft  = leftTileBorder <= -relativeVisibleBorders && rightTileBorder <= -relativeVisibleBorders
                let tooMuchRight = leftTileBorder >= relativeVisibleBorders  && rightTileBorder >= relativeVisibleBorders
                if tooMuchLeft || tooMuchRight {
                    continue
                }
                
                let centerX = relativeTileDeltaX * worldTileSize
                let centerY = relativeTileDeltaY * worldTileSize
                let scale = windowTileFraction * factor
                
                let scaleMatrix = MatrixUtils.matrix_scale(scale, scale, 1.0)
                let translateMatrix = MatrixUtils.matrix_translate(centerX, centerY, 0.0)
                let modelMatrix = translateMatrix * scaleMatrix
                
                drawTile.draw(renderEncoder: commandEncoder,
                              tile2dBuffers: metalTile.tile2dBuffers,
                              modelMatrix: modelMatrix)
            }
        }
        
        if Settings.drawHelpGridOnTexture {
            pipelines.basePipeline.selectPipeline(renderEncoder: commandEncoder)
            if currentZ > 1 {
                drawHelpGrid3(commandEncoder: commandEncoder)
            }
            if currentZ == 1 {
                drawHelpGrid2(commandEncoder: commandEncoder)
            }
        }
        
        commandEncoder.endEncoding()
    }
    
    private func drawHelpGrid3(commandEncoder: MTLRenderCommandEncoder) {
        var positions: [SIMD3<Float>] = []
        let segments = 3
        let thickness: Float = 0.004  // Adjustable thickness

        let step = 2.0 / Float(segments)
        var linePositions: [Float] = []
        for i in 0...segments {
            linePositions.append(-1.0 + Float(i) * step)
        }

        // Horizontal lines
        for y in linePositions {
            let half = thickness / 2
            let bl = SIMD3<Float>(-1, y - half, 0)
            let br = SIMD3<Float>(1, y - half, 0)
            let tl = SIMD3<Float>(-1, y + half, 0)
            let tr = SIMD3<Float>(1, y + half, 0)
            
            positions.append(bl)
            positions.append(br)
            positions.append(tl)
            positions.append(tl)
            positions.append(br)
            positions.append(tr)
        }

        // Vertical lines
        for x in linePositions {
            let half = thickness / 2
            let bl = SIMD3<Float>(x - half, -1, 0)
            let br = SIMD3<Float>(x + half, -1, 0)
            let tl = SIMD3<Float>(x - half, 1, 0)
            let tr = SIMD3<Float>(x + half, 1, 0)
            
            positions.append(bl)
            positions.append(br)
            positions.append(tl)
            positions.append(tl)
            positions.append(br)
            positions.append(tr)
        }
        
        let colors = positions.map { pos in SIMD4<Float>(1.0, 0.0, 0.0, 1.0) }
        commandEncoder.setVertexBytes(positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        commandEncoder.setVertexBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 1)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
    }
    
    private func drawHelpGrid2(commandEncoder: MTLRenderCommandEncoder) {
        var positions: [SIMD3<Float>] = []
        let segments = 2
        let thickness: Float = 0.004  // Adjustable thickness

        let step = 2.0 / Float(segments)
        var linePositions: [Float] = []
        for i in 0...segments {
            linePositions.append(-1.0 + Float(i) * step)
        }

        // Horizontal lines
        for y in linePositions {
            let half = thickness / 2
            let bl = SIMD3<Float>(-1, y - half, 0)
            let br = SIMD3<Float>(1, y - half, 0)
            let tl = SIMD3<Float>(-1, y + half, 0)
            let tr = SIMD3<Float>(1, y + half, 0)
            
            positions.append(bl)
            positions.append(br)
            positions.append(tl)
            positions.append(tl)
            positions.append(br)
            positions.append(tr)
        }

        // Vertical lines
        for x in linePositions {
            let half = thickness / 2
            let bl = SIMD3<Float>(x - half, -1, 0)
            let br = SIMD3<Float>(x + half, -1, 0)
            let tl = SIMD3<Float>(x - half, 1, 0)
            let tr = SIMD3<Float>(x + half, 1, 0)
            
            positions.append(bl)
            positions.append(br)
            positions.append(tl)
            positions.append(tl)
            positions.append(br)
            positions.append(tr)
        }
        
        let colors = positions.map { pos in SIMD4<Float>(1.0, 0.0, 0.0, 1.0) }
        commandEncoder.setVertexBytes(positions, length: MemoryLayout<SIMD3<Float>>.stride * positions.count, index: 0)
        commandEncoder.setVertexBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 1)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
    }
}
