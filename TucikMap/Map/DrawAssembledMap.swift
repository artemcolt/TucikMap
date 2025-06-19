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
    }
    
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    let drawMapLabels: DrawMapLabels
    let camera: Camera
    let mapZoomState: MapZoomState
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.drawMapLabels = DrawMapLabels(metalDevice: metalDevice, screenUniforms: screenUniforms, camera: camera)
        self.mapZoomState = mapZoomState
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
        let mapSize = Settings.mapSize
        
        var allTilesUniform = AllTilesUniform(
            mapSize: mapSize,
            panX: panX,
            panY: panY,
        )
        renderEncoder.setVertexBytes(&allTilesUniform, length: MemoryLayout<AllTilesUniform>.stride, index: 4)
        
        for tile in tiles {
            var tileUniform = TileUniform(
                tileX: simd_int1(tile.tile.x),
                tileY: simd_int1(tile.tile.y),
                tileZ: simd_int1(tile.tile.z),
            )
            
            renderEncoder.setVertexBuffer(tile.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&tileUniform, length: MemoryLayout<TileUniform>.stride, index: 3)
            
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
