//
//  TexturingTile.swift
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

import MetalKit

class GlobeTexturing {
    private let metalDevice         : MTLDevice
    private let metalCommandQueue   : MTLCommandQueue
    private let pipelines           : Pipelines
    private let drawTile            : DrawTile = DrawTile()
    private let uniformsBuffer      : MTLBuffer
    private let textureSize         : Int
    private let mapSettings         : MapSettings
    
    private var globeTextures: [MTLTexture] = []
    
    func getCurrentTexture(fbIndex: Int) -> MTLTexture {
        return globeTextures[fbIndex]
    }
    
    init(metalDevice: MTLDevice,
         metalCommandQueue: MTLCommandQueue,
         pipelines: Pipelines,
         mapSettings: MapSettings) {
        self.textureSize        = mapSettings.getMapCommonSettings().getGlobeTextureSize()
        self.metalDevice        = metalDevice
        self.metalCommandQueue  = metalCommandQueue
        self.pipelines          = pipelines
        self.mapSettings        = mapSettings
        
        let projectionMatrix    = MatrixUtils.orthographicMatrix(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
        var uniforms            = Uniforms(projectionMatrix: projectionMatrix,
                                           viewMatrix: matrix_identity_float4x4,
                                           viewportSize: SIMD2<Float>(0, 0),
                                           elapsedTimeSeconds: 0)
        
        uniformsBuffer          = metalDevice.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride)!
        
        let textureDescriptor   = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: textureSize,
                                                                         height: textureSize,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        for _ in 0..<mapSettings.getMapCommonSettings().getMaxBuffersInFlight() {
            let texture = metalDevice.makeTexture(descriptor: textureDescriptor)!
            globeTextures.append(texture)
        }
    }
    
    func render(commandBuffer: MTLCommandBuffer,
                metalTiles: [MetalTile],
                areaRange: AreaRange,
                currentFbIndex: Int) {
        
        
        let minTileX    = Float(areaRange.startX)
        let maxTileX    = Float(areaRange.endX)
        let minTileY    = Float(areaRange.minY)
        let maxTileY    = Float(areaRange.maxY)
        let currentZ    = Float(areaRange.z)
        let tilesNum    = Float(1 << areaRange.z)
        
        var visXCenter  = minTileX + (maxTileX - minTileX) / 2
        var visYCenter  = minTileY + (maxTileY - minTileY) / 2
        
        if areaRange.isFullMap {
            visXCenter = tilesNum / 2.0
            visYCenter = tilesNum / 2.0
        }
        
        let currentTexture = globeTextures[currentFbIndex]
        let normalTileSize = Float(2.0)
        let windowSize = Float(areaRange.tileXCount)
        let windowTileFraction = Float(1) / windowSize
        
        // Указываем текстуру как цель рендеринга
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture    = currentTexture
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
                
                if (areaRange.isFullMap == false) {
                    relativeTileDeltaX -= 0.5
                    relativeTileDeltaY += 0.5
                }
                
                relativeTileDeltaX -= difXFromCenter
                relativeTileDeltaY += difYFromCenter
                
                // пропускаем то что в итоге не отображается в текстуре
                let leftTileBorder = relativeTileDeltaX - factor / 2
                let rightTileBorder = relativeTileDeltaX + factor / 2
                let relativeVisibleBorders = Float(windowSize / 2.0)
                let tooMuchLeft  = leftTileBorder <= -relativeVisibleBorders && rightTileBorder <= -relativeVisibleBorders
                let tooMuchRight = leftTileBorder >= relativeVisibleBorders  && rightTileBorder >= relativeVisibleBorders
                if (tooMuchLeft || tooMuchRight) {
                    continue
                }
                
                let centerX = relativeTileDeltaX * worldTileSize
                let centerY = relativeTileDeltaY * worldTileSize
                let scale = windowTileFraction * factor
                
                let scaleMatrix = MatrixUtils.matrix_scale(scale, scale, 1.0)
                let translateMatrix = MatrixUtils.matrix_translate(centerX, centerY, 0.0)
                let modelMatrix = translateMatrix * scaleMatrix
                
                drawTile.setTileConsts(renderEncoder: commandEncoder, tile2dBuffers: metalTile.tile2dBuffers)
                drawTile.draw(renderEncoder: commandEncoder,
                              modelMatrix: modelMatrix,
                              tile2dBuffers: metalTile.tile2dBuffers)
            }
        }
        
        commandEncoder.endEncoding()
    }
}
