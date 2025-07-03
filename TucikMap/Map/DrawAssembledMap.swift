//
//  PolygonDraw.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit
import Foundation

class DrawAssembledMap {
    
    let mapSize = Settings.mapSize
    let metalDevice: MTLDevice
    let drawMapLabels: DrawMapLabels
    let camera: Camera
    let mapZoomState: MapZoomState
    
    init(metalDevice: MTLDevice, screenUniforms: ScreenUniforms, camera: Camera, mapZoomState: MapZoomState) {
        self.metalDevice = metalDevice
        self.drawMapLabels = DrawMapLabels(metalDevice: metalDevice, screenUniforms: screenUniforms, camera: camera, mapZoomState: mapZoomState)
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
        for tile in tiles {
            var modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            
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
    
    func draw3dTiles(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile]
    ) {
        guard tiles.isEmpty == false else { return }
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        
        let mapPanning = camera.mapPanning
        for tile in tiles {
            guard let vertices3DBuffer = tile.vertices3DBuffer,
                  let indices3DBuffer = tile.indices3DBuffer  else { continue }
            var modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile.tile, mapZoomState: mapZoomState, pan: mapPanning)
            
            renderEncoder.setVertexBuffer(vertices3DBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(tile.styles3DBuffer, offset: 0, index: 2)
            renderEncoder.setVertexBytes(&modelMatrix, length: MemoryLayout<float4x4>.stride, index: 3)
            
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: tile.indices3DCount,
                indexType: .uint32,
                indexBuffer: indices3DBuffer,
                indexBufferOffset: 0)
        }
    }
    
    
    func drawMapLabels(
        renderEncoder: MTLRenderCommandEncoder,
        uniformsBuffer: MTLBuffer,
        tiles: [MetalTile],
        currentFBIndex: Int
    ) {
        drawMapLabels.draw(
            renderEncoder: renderEncoder,
            tiles: tiles,
            uniformsBuffer: uniformsBuffer,
            currentFBIndex: currentFBIndex
        )
    }
}
