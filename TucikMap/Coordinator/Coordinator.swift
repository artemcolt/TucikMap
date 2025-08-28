//
//  Coordinator.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import SwiftUI
import MetalKit
import MetalPerformanceShaders

class Coordinator: NSObject, MTKViewDelegate {
    private let parent: TucikMapView
    private let scene: InitScene
    
    var cameraInputsHandler: CameraInputsHandler {
        get { scene.cameraInputsHandler }
    }
    
    init(_ parent: TucikMapView, mapSettings: MapSettings) {
        self.parent = parent
        self.scene = InitScene(mapSettings: mapSettings)
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.renderPassWrapper.mtkView(view: view, drawableSizeWillChange: size)
        
        let cameraSettings = scene.mapSettings.getMapCameraSettings()
        let latLon = cameraSettings.getLatLon()
        let z = cameraSettings.getZ()
        scene.mapController.moveTo(latitude: latLon.x, longitude: latLon.y, z: z)
        
        let initYaw = cameraSettings.getInitYaw()
        let initPitch = cameraSettings.getInitPitch()
        scene.mapController.setYawAndPitch(yaw: initYaw, pitch: initPitch)
        scene.mapController.updateMapIfNeeded(view: view, size: size)
        
        scene.renderFrameControl.updateView(view: view)
        scene.screenUniforms.update(size: size)
        scene.flatMode.mtkView(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        // Wait until the previous frame's GPU work has completed
        // This ensures we don't try to update a buffer that's still in use
        _ = scene.semaphore.wait(timeout: .distantFuture)
        
        // Обработка комманд карте
        scene.mapController.updateMapIfNeeded(view: view, size: view.drawableSize)
        
        guard let commandBuffer = scene.metalCommandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor?.copy() as? MTLRenderPassDescriptor else {
            scene.semaphore.signal()
            return
        }
        
        scene.renderPassWrapper.startFrame(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        // Add completion handler to signal the semaphore when GPU work is done
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.scene.semaphore.signal()
        }
        
        // Поменять режим рендринга когда нужно
        // Глобус / Плоскость
        let switched = scene.switchMapMode.switchingMapMode(view: view)
        scene.renderPassWrapper.updateClearColor(switchMapMode: scene.switchMapMode)
        
        // Юниформ для трансформации сцены в clip
        scene.updateBufferedUniform.updateUniforms(viewportSize: view.drawableSize)
        
        let currentFBIdx = scene.updateBufferedUniform.getCurrentFrameBufferIndex()
        let lastUniforms = scene.updateBufferedUniform.lastUniforms!
        let camera = scene.cameraStorage.currentView
        let mapPanning = camera.mapPanning
        let mapSize = camera.mapSize
        
        // Если камера поменяла состояние то нужно обновить саму карту, тайлы
        if scene.cameraStorage.currentView.isMapStateUpdated() || switched {
            scene.mapUpdaterStorage.currentView.update(view: view, useOnlyCached: false)
        }
        
        let cameraQuaternion = camera.cameraQuaternion;
        let baseNormal = SIMD3<Float>(0, 0, 1)
        let traversalPlaneNormal = cameraQuaternion.act(baseNormal)
        
        // Расчет экранной UI информации, пересечения текста например
        if (scene.mapCadDisplayLoop.checkEvaluateScreenData()) {
            switch scene.mapModeStorage.mapMode {
            case .flat: let _ = scene.scrCollDetStorage.flat.evaluateFlat(lastUniforms: lastUniforms,
                                                                          mapPanning: mapPanning,
                                                                          mapSize: mapSize)
            case .globe: let _ = scene.scrCollDetStorage.globe.evaluateGlobe(lastUniforms: lastUniforms,
                                                                             latitude: camera.latitude,
                                                                             longitude: camera.longitude,
                                                                             globeRadius: camera.globeRadius,
                                                                             cameraPosition: camera.cameraPosition,
                                                                             transition: scene.switchMapMode.transition,
                                                                             planeNormal: traversalPlaneNormal)
            }
        }
        
        // Применяем если есть актуальные данные меток для свежего кадра
        scene.applyLabelsState.apply(currentFBIdx: currentFBIdx)
        
        switch scene.mapModeStorage.mapMode {
        case .flat:
            scene.flatMode.draw(in: view, renderPassWrapper: scene.renderPassWrapper)
        case .globe:
            scene.globeMode.draw(in: view, renderPassWrapper: scene.renderPassWrapper)
        }
        
        
        // Вывести на экран, на основную текстуру отрисованную текстуру
//        scene.drawTextureOnScreen.draw(currentRenderPassDescriptor: view.currentRenderPassDescriptor,
//                                       commandBuffer: commandBuffer,
//                                       sceneTexture: scene.renderPassWrapper.getScreenTexture())
        
        commandBuffer.present(drawable)
        scene.frameCounter.update(with: commandBuffer)
        commandBuffer.commit()
    }
}


