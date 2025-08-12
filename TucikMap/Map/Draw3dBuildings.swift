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
    
    private let polygon3dPipeline               : Polygon3dPipeline
    private let drawAssembledMap                : DrawAssembledMap
    private let metalDevice                     : MTLDevice
    
    init(polygon3dPipeline: Polygon3dPipeline, drawAssembledMap: DrawAssembledMap, metalDevice: MTLDevice) {
        self.polygon3dPipeline = polygon3dPipeline
        self.drawAssembledMap = drawAssembledMap
        self.metalDevice = metalDevice
        
        let depthPrePassDescriptor  = MTLDepthStencilDescriptor()
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
    }
    
    func draw(renderPassWrapper: RenderPassWrapper, uniformsBuffer: MTLBuffer, assembledTiles: [MetalTile], tileFrameProps: TileFrameProps) {
        renderPassWrapper.useDepthStencil()
        let depthPrePassEncoder = renderPassWrapper.create3dBuildingFirstEncoder()
        polygon3dPipeline.selectPipeline(renderEncoder: depthPrePassEncoder)
        depthPrePassEncoder.setDepthStencilState(depthStencilStatePrePass)
        depthPrePassEncoder.setCullMode(.back)
        drawAssembledMap.draw3dTiles(
            renderEncoder: depthPrePassEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        depthPrePassEncoder.endEncoding()
        
        let colorPassEncoder = renderPassWrapper.create3dBuildingSecondEncoder()
        polygon3dPipeline.selectPipeline(renderEncoder: colorPassEncoder)
        colorPassEncoder.setDepthStencilState(depthStencilStateColorPass)
        colorPassEncoder.setStencilReferenceValue(0)
        colorPassEncoder.setCullMode(.back)
        drawAssembledMap.draw3dTiles(
            renderEncoder: colorPassEncoder,
            uniformsBuffer: uniformsBuffer,
            tiles: assembledTiles,
            tileFrameProps: tileFrameProps
        )
        colorPassEncoder.endEncoding()
    }
}
