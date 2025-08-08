//
//  ModelMatrices.swift
//  TucikMap
//
//  Created by Artem on 7/22/25.
//

import MetalKit

class PrepareToScreenData {
    var tileToIndex: [Tile:Int] = [:]
    var mapZoomState: MapZoomState
    var resultSize: Int
    
    init(mapZoomState: MapZoomState) {
        self.mapZoomState = mapZoomState
        self.resultSize = 0
    }
    
    func getForScreenDataIndex(tile: Tile) -> Int { return -1 }
}

class PrepareToScreenDataGlobe : PrepareToScreenData {
    private(set) var parameters: [CompScreenGlobePipe.Parmeters] = []
    private(set) var latitude: Float
    private(set) var longitude: Float
    private(set) var globeRadius: Float
    
    init(mapZoomState: MapZoomState,
         mapPanning: SIMD3<Double>,
         latitude: Float,
         longitude: Float,
         globeRadius: Float) {
        self.latitude = latitude
        self.longitude = longitude
        self.globeRadius = globeRadius
        
        super.init(mapZoomState: mapZoomState)
    }
    
    override func getForScreenDataIndex(tile: Tile) -> Int {
        var indexTo = tileToIndex[tile]
        if indexTo == nil {
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
        return indexTo!
    }
}

class PrepareToScreenDataFlat : PrepareToScreenData {
    private(set) var matrices: [matrix_float4x4] = []
    private var mapSize: Float
    private var mapPanning: SIMD3<Double>
    
    init(mapZoomState: MapZoomState, mapPanning: SIMD3<Double>, mapSize: Float) {
        self.mapSize = mapSize
        self.mapPanning = mapPanning
        super.init(mapZoomState: mapZoomState)
    }
    
    override func getForScreenDataIndex(tile: Tile) -> Int {
        var indexTo = tileToIndex[tile]
        if indexTo == nil {
            let modelMatrix = MapMathUtils.getTileModelMatrix(tile: tile, mapZoomState: mapZoomState, pan: mapPanning, mapSize: mapSize)
            indexTo = matrices.count
            tileToIndex[tile] = indexTo
            matrices.append(modelMatrix)
            resultSize = matrices.count
        }
        return indexTo!
    }
}
