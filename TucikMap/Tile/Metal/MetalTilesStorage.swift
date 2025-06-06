//
//  MetalTilesStorage.swift
//  TucikMap
//
//  Created by Artem on 6/6/25.
//

import Foundation
import GISTools
import MetalKit

class MetalTilesStorage {
    private var mapNeedsTile: MapNeedsTile!
    private var tileParser: TileMvtParser!
    private var memoryMetalTile: MemoryMetalTileCache!
    private var debouncer: Debouncer<(Data, Tile)>!
    private let onProcessedTiles: () -> Void
    
    private let metalDevice: MTLDevice
    
    init(determineStyle: DetermineFeatureStyle, metalDevice: MTLDevice, onProcessedTiles: @escaping () -> Void) {
        self.metalDevice = metalDevice
        self.onProcessedTiles = onProcessedTiles
        memoryMetalTile = MemoryMetalTileCache()
        tileParser = TileMvtParser(determineFeatureStyle: determineStyle)
        mapNeedsTile = MapNeedsTile(onComplete: onTileComplete)
        debouncer = Debouncer(debounceInterval: Settings.tilesCompleteDebounceInterval, processHandler: processTiles)
    }
    
    private func onTileComplete(data: Data, tile: Tile) {
        if Settings.debugAssemblingMap { print("Add item to debounder \(tile)") }
        debouncer.addItem((data, tile))
    }
    
    func getMetalTile(tile: Tile) -> MetalTile? {
        return memoryMetalTile.tile(forKey: tile.key())
    }
    
    func requestMetalTile(tile: Tile) {
        mapNeedsTile.please(tile: tile)
    }
    
    // Debouncer thread
    private func processTiles(debouncedTiles: [(Data, Tile)]) {
        let tiles = debouncedTiles.suffix(Settings.visibleTilesCount)
        if (Settings.debugAssemblingMap) {print("Parsing and Metaling. Debounced: \(debouncedTiles.count). Tiles: \(tiles.count).")}
        
        var saveToMemory: [(MetalTile, Tile)] = []
        for tileItem in tiles {
            let data = tileItem.0
            let tile = tileItem.1
            let parsedTile = tileParser.parse(
                tile: tile,
                mvtData: data,
                boundingBox: BoundingBox(
                    southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
                    northEast: Coordinate3D(latitude: Double(Settings.tileExtent), longitude: Double(Settings.tileExtent))
                )
            )
            
            let verticesBuffer = metalDevice.makeBuffer(
                bytes: parsedTile.drawingPolygon.vertices,
                length: parsedTile.drawingPolygon.vertices.count * MemoryLayout<PolygonPipeline.VertexIn>.stride
            )!
            let indicesBuffer = metalDevice.makeBuffer(
                bytes: parsedTile.drawingPolygon.indices,
                length: parsedTile.drawingPolygon.indices.count * MemoryLayout<UInt32>.stride
            )!
            let stylesBuffer = metalDevice.makeBuffer(
                bytes: parsedTile.styles,
                length: parsedTile.styles.count * MemoryLayout<TilePolygonStyle>.stride
            )!
            let modelMatrixBuffer = metalDevice.makeBuffer(bytes: &parsedTile.modelMatrix, length: MemoryLayout<matrix_float4x4>.stride)!
            
            let metalTile = MetalTile(
                verticesBuffer: verticesBuffer,
                indicesBuffer: indicesBuffer,
                indicesCount: parsedTile.drawingPolygon.indices.count,
                stylesBuffer: stylesBuffer,
                modelMatrixBuffer: modelMatrixBuffer,
                tile: tile
            )
            
            saveToMemory.append((metalTile, tile))
        }
        
        // tiles processed
        DispatchQueue.main.async {
            for data in saveToMemory {
                self.memoryMetalTile.setTile(data.0, forKey: data.1.key())
            }
            self.onProcessedTiles()
        }
    }
}
