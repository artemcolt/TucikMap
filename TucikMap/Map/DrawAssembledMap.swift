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
        let panX = Double(mapPanning.x)
        let panY = Double(mapPanning.y)
        let mapSize = Double(Settings.mapSize)
        
        for tile in tiles {
            let zoomFactor = pow(2.0, Double(tile.tile.z));
            
            let tileCenterX = Double(tile.tile.x) + 0.5;
            let tileCenterY = Double(tile.tile.y) + 0.5;
            let tileSize = mapSize / zoomFactor;
            
            let tileWorldX = tileCenterX * tileSize - mapSize / 2;
            let tileWorldY = mapSize / 2 - tileCenterY * tileSize;
            
            let scaleX = tileSize / 2;
            let scaleY = tileSize / 2;
            let offsetX = tileWorldX + panX;
            let offsetY = tileWorldY + panY;
            
            var modelMatrix = MatrixUtils.createTileModelMatrix(
                scaleX: Float(scaleX),
                scaleY: Float(scaleY),
                offsetX: Float(offsetX),
                offsetY: Float(offsetY)
            )
            
            renderEncoder.setVertexBuffer(tile.verticesBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile.stylesBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 3)
            
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
