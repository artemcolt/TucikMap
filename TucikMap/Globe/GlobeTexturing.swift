//
//  TexturingTile.swift
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

import MetalKit

class GlobeTexturing {
    struct RenderingBlock {
        let tiles: [MetalTile]
        let areaRange: AreaRange
    }
    
    private let metalDevide         : MTLDevice
    private let metalCommandQueue   : MTLCommandQueue
    private let pipelines           : Pipelines
    private let drawTile            : DrawTile = DrawTile()
    private var renderingBlock      : RenderingBlock = RenderingBlock(tiles: [], areaRange: AreaRange(minX: 0, minY: 0, maxX: 0, maxY: 0, z: 0))
    private var updateFrameCounter  : Int = 0
    private let uniformsBuffer      : MTLBuffer
    private let textureSize         : Int = 4096
    private var texturesBuffered    : [MTLTexture] = []
    
    func lastTextureAreaRange() -> AreaRange {
        return renderingBlock.areaRange
    }
    
    func updateTexture(currentFBIndex: Int, commandBuffer: MTLCommandBuffer) {
        if updateFrameCounter > 0 {
            render(currentFBIndex: currentFBIndex,
                   metalTiles: renderingBlock.tiles,
                   commandBuffer: commandBuffer)
            updateFrameCounter -= 1
        }
    }
    
    func setRenderingBlock(renderingBlock: RenderingBlock) {
        if renderingBlock.tiles.isEmpty { return }
        self.renderingBlock = renderingBlock
        self.updateFrameCounter = Settings.maxBuffersInFlight
    }
    
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
                metalTiles: [MetalTile],
                commandBuffer: MTLCommandBuffer) {
        let texture                 = texturesBuffered[currentFBIndex]
        let renderPassDescriptor    = MTLRenderPassDescriptor()
        
        // Указываем текстуру как цель рендеринга
        renderPassDescriptor.colorAttachments[0].texture    = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        pipelines.polygonPipeline.selectPipeline(renderEncoder: commandEncoder)
        drawTile.setUniforms(renderEncoder: commandEncoder, uniformsBuffer: uniformsBuffer)
        
        let areaRange   = renderingBlock.areaRange
        let minTileX    = areaRange.minX
        let maxTileX    = areaRange.maxX
        let minTileY    = areaRange.minY
        let maxTileY    = areaRange.maxY
        let currentZ    = areaRange.z

        let numVisTiles = Float(1 << currentZ)
        let u_min = Float(minTileX) / numVisTiles
        let u_max = Float(maxTileX + 1) / numVisTiles
        let clamped_u_min = max(u_min, 0.0)
        let clamped_u_max = min(u_max, 1.0)
        let delta_u = clamped_u_max - clamped_u_min

        let v_min = Float(minTileY) / numVisTiles
        let v_max = Float(maxTileY + 1) / numVisTiles
        let clamped_v_min = max(v_min, 0.0)
        let clamped_v_max = min(v_max, 1.0)
        let delta_v = clamped_v_max - clamped_v_min

        // Assuming delta_u == delta_v since the visible area is always square
        let delta = delta_u  // or delta_v, as they should be equal

        for metalTile in metalTiles {
            let tile = metalTile.tile
            let x = tile.x
            let y = tile.y
            let z = tile.z
            
            let numTiles = Float(1 << z)  // Equivalent to pow(2, Float(z))
            let tileFraction = 1.0 / numTiles
            let uCenter = (Float(x) + 0.5) * tileFraction
            let vCenter = (Float(y) + 0.5) * tileFraction
            
            let normalized_u = (uCenter - clamped_u_min) / delta_u
            let centerX = -1.0 + 2.0 * normalized_u
            
            let normalized_v = (vCenter - clamped_v_min) / delta_v
            let centerY = 1.0 - 2.0 * normalized_v
            
            let scale = tileFraction / delta
            
            let scaleMatrix = MatrixUtils.matrix_scale(scale, scale, 1.0)
            let translateMatrix = MatrixUtils.matrix_translate(centerX, centerY, 0.0)
            let modelMatrix = translateMatrix * scaleMatrix
            
            drawTile.draw(renderEncoder: commandEncoder,
                          tile2dBuffers: metalTile.tile2dBuffers,
                          modelMatrix: modelMatrix)
        }
        
        commandEncoder.endEncoding()
    }
}
