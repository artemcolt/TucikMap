//
//  ModelMatrices.swift
//  TucikMap
//
//  Created by Artem on 7/22/25.
//

import MetalKit

class PrepareToScreenData {
    private let mapMode: MapMode
    private var matrices: [matrix_float4x4] = []
    private var parameters: [CompScreenGlobePipe.Parmeters] = []
    private var tileToIndex: [Tile:Int] = [:]
    private var mapZoomState: MapZoomState
    private var mapPanning: SIMD3<Double>
    private var mapSize: Float
    private var latitude: Float
    private var longitude: Float
    private var globeRadius: Float
    private(set) var resultSize: Int
    
    func getMatricesArray() -> [matrix_float4x4] {
        return matrices
    }
    
    func getParametersArray() -> [CompScreenGlobePipe.Parmeters] {
        return parameters
    }
    
    init(mapZoomState: MapZoomState,
         mapPanning: SIMD3<Double>,
         mapSize: Float,
         latitude: Float,
         longitude: Float,
         globeRadius: Float,
         mapMode: MapMode) {
        self.mapZoomState = mapZoomState
        self.mapPanning = mapPanning
        self.mapSize = mapSize
        self.mapMode = mapMode
        self.latitude = latitude
        self.longitude = longitude
        self.globeRadius = globeRadius
        self.resultSize = 0
    }
    
    func getForScreenDataIndex(tile: Tile) -> Int {
        var indexTo = tileToIndex[tile]
        if indexTo == nil {
            switch mapMode {
            case .flat:
                let modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile, mapZoomState: mapZoomState, pan: mapPanning, mapSize: mapSize)
                indexTo = matrices.count
                tileToIndex[tile] = indexTo
                matrices.append(modelMatrix)
                resultSize = matrices.count
            case .globe:
                let centerTileX = Float(tile.x) + 0.5
                let centerTileY = Float(tile.y) + 0.5
                let z = Float(tile.z)
                let factor = 1.0 / pow(2, z)
                let tilesNum = pow(2, z)
                let centerX = -1.0 + (centerTileX / tilesNum) * 2.0
                let centerY = (1.0 - (centerTileY / tilesNum) * 2.0)
                
                let param = CompScreenGlobePipe.Parmeters(latitude: latitude,
                                                          longitude: longitude,
                                                          globeRadius: globeRadius,
                                                          centerX: centerX,
                                                          centerY: centerY,
                                                          factor: factor)
                indexTo = parameters.count
                tileToIndex[tile] = indexTo
                parameters.append(param)
                resultSize = parameters.count
            }
        }
        return indexTo!
    }
}
