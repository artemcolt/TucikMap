//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit
import Foundation

class DrawAssembledMap {
    
    struct DrawLabelsFinal {
        var result: MapLabelsAssembler.Result
        var pan: SIMD2<Float>
    }
    
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    let drawMapLabels: DrawMapLabels
    let camera: Camera
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera) {
        self.metalDevice = metalDevice
        self.drawMapLabels = DrawMapLabels(metalDevice: metalDevice, screenUniforms: screenUniforms, camera: camera)
        self.camera = camera
    }
    
    func drawTiles(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile]
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        let mapPanning = camera.mapPanning
        let panX = mapPanning.x
        let panY = mapPanning.y
        
        for tile in tiles {
            let mapParameters = MapZParameters(z: tile.tile.z)
            let tileSize = mapParameters.tileSize
            
            let tileCenterX = Float(tile.tile.x) + 0.5
            let tileCenterY = Float(tile.tile.y) + 0.5
            
            let tileWorldX = tileCenterX * Float(tileSize) - Settings.mapSize / 2
            let tileWorldY = Settings.mapSize / 2 - tileCenterY * Float(tileSize)
            
            let offsetX = tileWorldX + panX
            let offsetY = tileWorldY + panY
            
            var matrix = MatrixUtils.createTileModelMatrix(
                scaleX: Float(mapParameters.scaleX),
                scaleY: Float(mapParameters.scaleY),
                offsetX: offsetX,
                offsetY: offsetY
            )
            
            renderEncoder.setVertexBuffer(tile.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&matrix, length: MemoryLayout<float4x4>.stride, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: tile.indicesCount,
                indexType: .uint32,
                indexBuffer: tile.indicesBuffer,
                indexBufferOffset: 0)
        }
    }
    
    func drawMapLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniforms: MTLBuffer,
        result: DrawLabelsFinal?
    ) {
        if let result = result {
            drawMapLabels.draw(
                renderEncoder: renderEncoder,
                drawLabelsFinal: result,
                uniforms: uniforms
            )
        }
    }
}
