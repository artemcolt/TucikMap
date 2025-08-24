//
//  MapController.swift
//  TucikMap
//
//  Created by Artem on 8/24/25.
//

class MapController {
    private let drawingFrameRequester: DrawingFrameRequester
    private let cameraStorage: CameraStorage
    private var needUpdate: Bool = false

    init(drawingFrameRequester: DrawingFrameRequester, cameraStorage: CameraStorage) {
        self.drawingFrameRequester = drawingFrameRequester
        self.cameraStorage = cameraStorage
    }
    
    func getNeedUpdate() -> Bool {
        if needUpdate {
            needUpdate = false
            return true
        }
        return false
    }

    func moveTo(latitude: Double, longitude: Double, z: Float) {
        cameraStorage.currentView.moveTo(lat: latitude, lon: longitude, zoom: z)
        needUpdate = true
        drawingFrameRequester.renderNextStep()
    }
}
