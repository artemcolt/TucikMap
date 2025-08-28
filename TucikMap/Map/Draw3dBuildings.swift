//
//  Draw3dBuildings.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import MetalKit

class Draw3dBuildings {
    private var depthStencilStatePrePass        : MTLDepthStencilState!
    private var depthStencilStateColorPass      : MTLDepthStencilState!
    private var depthStencilStateAllowAll       : MTLDepthStencilState!
    
    private let polygon3dPipeline               : Polygon3dPipeline
    private let drawAssembledMap                : DrawAssembledMap
    private let metalDevice                     : MTLDevice
    
    init(polygon3dPipeline: Polygon3dPipeline, drawAssembledMap: DrawAssembledMap, metalDevice: MTLDevice) {
        self.polygon3dPipeline = polygon3dPipeline
        self.drawAssembledMap = drawAssembledMap
        self.metalDevice = metalDevice
        
        let depthPrePassDescriptor = MTLDepthStencilDescriptor()
        depthPrePassDescriptor.depthCompareFunction = .less
        depthPrePassDescriptor.isDepthWriteEnabled = true
        depthStencilStatePrePass = metalDevice.makeDepthStencilState(descriptor: depthPrePassDescriptor)
        
        let depthColorPassDescriptor = MTLDepthStencilDescriptor()
        depthColorPassDescriptor.depthCompareFunction = .equal  // Key change: only equal depths pass
        depthColorPassDescriptor.isDepthWriteEnabled = false   // No need to write depth again
        
        // Настройка stencil-теста
        let stencilDescriptor = MTLStencilDescriptor()
        stencilDescriptor.stencilCompareFunction = .equal
        stencilDescriptor.stencilFailureOperation = .keep
        stencilDescriptor.depthFailureOperation = .keep
        stencilDescriptor.depthStencilPassOperation = .incrementClamp // Увеличиваем stencil при рендеринге
        stencilDescriptor.readMask = 0xFF
        stencilDescriptor.writeMask = 0xFF
        depthColorPassDescriptor.frontFaceStencil = stencilDescriptor
        depthStencilStateColorPass = metalDevice.makeDepthStencilState(descriptor: depthColorPassDescriptor)!
        
        
        let depthColorPassDescriptor3 = MTLDepthStencilDescriptor()
        depthColorPassDescriptor.depthCompareFunction = .always  // Key change: only equal depths pass
        depthColorPassDescriptor.isDepthWriteEnabled = false   // No need to write depth again
        depthStencilStateAllowAll = metalDevice.makeDepthStencilState(descriptor: depthColorPassDescriptor3)!
    }
    
    func draw(renderEncoder: MTLRenderCommandEncoder, assembledTiles: [MetalTile], tileFrameProps: TileFrameProps) {
        polygon3dPipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setDepthStencilState(depthStencilStateColorPass)
        renderEncoder.setStencilReferenceValue(0)
        renderEncoder.setCullMode(.back)
        drawAssembledMap.draw3dTiles(
            renderEncoder: renderEncoder,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        
        renderEncoder.setCullMode(.front)
        renderEncoder.setDepthStencilState(depthStencilStateAllowAll)
    }
    
    func prepass(renderEncoder: MTLRenderCommandEncoder, assembledTiles: [MetalTile], tileFrameProps: TileFrameProps) {
        polygon3dPipeline.selectPipeline(renderEncoder: renderEncoder)
        renderEncoder.setDepthStencilState(depthStencilStatePrePass)
        renderEncoder.setCullMode(.back)
        drawAssembledMap.draw3dTiles(
            renderEncoder: renderEncoder,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
    }
}
