//
//  RenderPassWrapper.swift
//  TucikMap
//
//  Created by Artem on 8/12/25.
//

import MetalKit
import SwiftUI

class RenderPassWrapper {
    private let metalDevice: MTLDevice
    
    private var view: MTKView!
    private(set) var texture0: MTLTexture!
    private(set) var commandBuffer: MTLCommandBuffer!
    
    private var renderPassDescriptor: MTLRenderPassDescriptor!
    
    init(metalDevice: MTLDevice) {
        self.metalDevice = metalDevice
        
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        self.view = view
        let sceneTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                              width: Int(size.width),
                                                                              height: Int(size.height),
                                                                              mipmapped: false)
        
        sceneTextureDescriptor.usage = [.renderTarget, .shaderRead]
        sceneTextureDescriptor.storageMode = .private
        texture0 = metalDevice.makeTexture(descriptor: sceneTextureDescriptor)!
    }
    
    func createGlobeTransversalEncoder() -> MTLRenderCommandEncoder {
        useDepthStencil()
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.loadAction = .load
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        return encoder(renderPassDescriptor)
    }
    
    func createUIEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.texture = nil
        renderPassDescriptor.stencilAttachment.texture = nil
        return encoder(renderPassDescriptor)
    }
    
    func createLabelsFlatEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.depthAttachment = nil
        renderPassDescriptor.stencilAttachment = nil
        return encoder(renderPassDescriptor)
    }
    
    func changeScreenTexture(texture: MTLTexture) {
        renderPassDescriptor.colorAttachments[0].texture = texture
    }
    
    func getScreenTexture() -> MTLTexture {
        return renderPassDescriptor.colorAttachments[0].texture!
    }
    
    func startFrame(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        self.renderPassDescriptor = renderPassDescriptor
        self.commandBuffer = commandBuffer
        //renderPassDescriptor.colorAttachments[0].texture = texture0
    }
    
    func updateClearColor(switchMapMode: SwitchMapMode) {
        let modeTransition = Double(switchMapMode.transition)
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: modeTransition,
                                                                            green: modeTransition,
                                                                            blue: modeTransition,
                                                                            alpha: 1.0)
    }
    
    func useDepthStencil() {
        renderPassDescriptor.depthAttachment.texture = view.depthStencilTexture
        renderPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
    }
    
    func create3dBuildingFirstEncoder() -> MTLRenderCommandEncoder {
        let depthPrePassDescriptor = renderPassDescriptor.copy() as! MTLRenderPassDescriptor
        depthPrePassDescriptor.colorAttachments[0].loadAction = .dontCare  // No color load needed
        depthPrePassDescriptor.colorAttachments[0].storeAction = .dontCare // Disable color writes
        depthPrePassDescriptor.depthAttachment.loadAction = .clear         // Clear depth
        depthPrePassDescriptor.depthAttachment.storeAction = .store        // Keep depth for next pass
        depthPrePassDescriptor.depthAttachment.clearDepth = 1.0
        return encoder(depthPrePassDescriptor)
    }
    
    func create3dBuildingSecondEncoder() -> MTLRenderCommandEncoder {
        let colorPassDescriptor = renderPassDescriptor.copy() as! MTLRenderPassDescriptor
        colorPassDescriptor.depthAttachment.texture = view.depthStencilTexture
        colorPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
        colorPassDescriptor.colorAttachments[0].loadAction = .load
        colorPassDescriptor.colorAttachments[0].storeAction = .store
        colorPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // Background color
        colorPassDescriptor.depthAttachment.loadAction = .load       
        colorPassDescriptor.depthAttachment.storeAction = .dontCare
        return encoder(colorPassDescriptor)
    }
    
    func createFlatEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment = nil
        renderPassDescriptor.stencilAttachment = nil
        
        return encoder(renderPassDescriptor)
    }
    
    func createRoadLabelsEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment = nil
        renderPassDescriptor.stencilAttachment = nil
        return encoder(renderPassDescriptor)
    }
    
    
    func createGlobeModeEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        return encoder(renderPassDescriptor)
    }
    
    func createGlobeEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = view.depthStencilTexture
        renderPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .dontCare
        return encoder(renderPassDescriptor)
    }
    
    func createLabelsEncoder() -> MTLRenderCommandEncoder {
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment = nil
        renderPassDescriptor.stencilAttachment = nil
        return encoder(renderPassDescriptor)
    }
    
    private func encoder(_ descriptor: MTLRenderPassDescriptor) -> MTLRenderCommandEncoder {
        return commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    }
}
