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
    private let textureSize         : Int = 2048
    
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
    
    func render(currentFBIndex: Int, metalTiles: [MetalTile]) {
        guard let commandBuffer     = metalCommandQueue.makeCommandBuffer() else { return }
        let texture                 = texturesBuffered[currentFBIndex]
        let renderPassDescriptor    = MTLRenderPassDescriptor()
        
        // Указываем текстуру как цель рендеринга
        renderPassDescriptor.colorAttachments[0].texture    = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        pipelines.polygonPipeline.selectPipeline(renderEncoder: commandEncoder)
        drawTile.setUniforms(renderEncoder: commandEncoder, uniformsBuffer: uniformsBuffer)
        for metalTile in metalTiles {
            let tile = metalTile.tile
            let x = tile.x
            let y = tile.y
            let z = tile.z
            
            let numTiles = Float(1 << z)  // Equivalent to pow(2, Float(z))
            let tileFraction = 1.0 / numTiles
            let uCenter = (Float(x) + 0.5) * tileFraction
            let vCenter = (Float(y) + 0.5) * tileFraction
            let centerX = -1.0 + 2.0 * uCenter
            let centerY = 1.0 - 2.0 * vCenter
            let scale = tileFraction

            let scaleMatrix = MatrixUtils.matrix_scale(scale, scale, 1.0)
            let translateMatrix = MatrixUtils.matrix_translate(centerX, centerY, 0.0)
            let modelMatrix = translateMatrix * scaleMatrix
            
            drawTile.draw(renderEncoder: commandEncoder,
                          tile2dBuffers: metalTile.tile2dBuffers,
                          modelMatrix: modelMatrix)
        }
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
    }
}
