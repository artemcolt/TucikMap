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
    private var mapNeedsTile        : MapNeedsTile!
    private var tileParser          : TileMvtParser!
    private var memoryMetalTile     : MemoryMetalTileCache!
    private var onMetalingTileEnd   : [(Tile) -> Void] = []
    private let textTools           : TextTools
    private let metalDevice         : MTLDevice
    private let mapSettings         : MapSettings
    
    init(
        determineStyle: DetermineFeatureStyle,
        metalDevice: MTLDevice,
        textTools: TextTools,
        mapSettings: MapSettings
    ) {
        self.mapSettings = mapSettings
        self.textTools = textTools
        self.metalDevice = metalDevice
        let maxCachedTilesMemory = mapSettings.getMapCommonSettings().getMaxCachedTilesMemory()
        memoryMetalTile = MemoryMetalTileCache(maxCacheSizeInBytes: maxCachedTilesMemory)
        tileParser = TileMvtParser(determineFeatureStyle: determineStyle, mapSettings: mapSettings)
        mapNeedsTile = MapNeedsTile(mapSettings: mapSettings, onComplete: onTileComplete)
    }
    
    func addHandler(handler: @escaping (Tile) -> Void) {
        onMetalingTileEnd.append(handler)
    }
    
    private func onTileComplete(data: Data?, tile: Tile) {
        guard let data = data else { return }
        
        let debugAssemblingMap = mapSettings.getMapDebugSettings().getDebugAssemblingMap()
        let tileExtent = mapSettings.getMapCommonSettings().getTileExtent()
        let roadLabelTextSize = mapSettings.getMapCommonSettings().getRoadLabelTextSize()
        if debugAssemblingMap { print("Parsing and metaling \(tile)") }
        Task {
            let parsedTile = await tileParser.parse(
                tile: tile,
                mvtData: data,
                boundingBox: BoundingBox(
                    southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
                    northEast: Coordinate3D(latitude: Double(tileExtent), longitude: Double(tileExtent))
                )
            )
            
            let tile2dBuffers = Tile2dBuffers(
                verticesBuffer: metalDevice.makeBuffer(
                    bytes: parsedTile.drawingPolygon.vertices,
                    length: parsedTile.drawingPolygon.vertices.count * MemoryLayout<PolygonPipeline.VertexIn>.stride
                )!,
                indicesBuffer: metalDevice.makeBuffer(
                    bytes: parsedTile.drawingPolygon.indices,
                    length: parsedTile.drawingPolygon.indices.count * MemoryLayout<UInt32>.stride
                )!,
                stylesBuffer: metalDevice.makeBuffer(
                    bytes: parsedTile.styles,
                    length: parsedTile.styles.count * MemoryLayout<TilePolygonStyle>.stride
                )!,
                indicesCount: parsedTile.drawingPolygon.indices.count
            )
            
            let tile3dBuffers = Tile3dBuffers(
                verticesBuffer: parsedTile.drawing3dPolygon.vertices.isEmpty ? nil : metalDevice.makeBuffer(
                    bytes: parsedTile.drawing3dPolygon.vertices,
                    length: parsedTile.drawing3dPolygon.vertices.count * MemoryLayout<Polygon3dPipeline.VertexIn>.stride
                ),
                indicesBuffer: parsedTile.drawing3dPolygon.indices.isEmpty ? nil : metalDevice.makeBuffer(
                    bytes: parsedTile.drawing3dPolygon.indices,
                    length: parsedTile.drawing3dPolygon.indices.count * MemoryLayout<UInt32>.stride
                ),
                stylesBuffer: metalDevice.makeBuffer(
                    bytes: parsedTile.styles3d,
                    length: parsedTile.styles3d.count * MemoryLayout<TilePolygonStyle>.stride
                )!,
                indicesCount: parsedTile.drawing3dPolygon.indices.count
            )
            
            let roadLabelsParsed = parsedTile.roadLabels
            let roadLabels = textTools.mapRoadLabelsAssembler.assemble(
                lines: roadLabelsParsed.map { roadLabel in
                    MapRoadLabelsAssembler.TextLineData(
                        text: roadLabel.name,
                        scale: roadLabelTextSize,
                        localPositions: roadLabel.localPoints,
                        id: roadLabel.id,
                        sortRank: 0,
                        pathLen: roadLabel.pathLen
                    )
                },
                font: textTools.baseFont
            )
            
            let textLabels = textTools.mapLabelsAssembler.assemble(
                lines: parsedTile.textLabels.map { label in MapLabelsAssembler.TextLineData(
                    // это для GPU данные, для шейдера
                    text: label.nameEn,
                    scale: label.scale,
                    localPosition: label.localPosition,
                    // это для рассчета коллизии на cpu
                    id: label.id,
                    sortRank: label.sortRank
                )},
                font: textTools.baseFont
            )
            
            let metalTile = MetalTile(
                tile: tile,
                tile2dBuffers: tile2dBuffers,
                tile3dBuffers: tile3dBuffers,
                
                textLabels: textLabels,
                roadLabels: roadLabels
            )
            
            await MainActor.run {
                let key = tile.key()
                self.memoryMetalTile.setTileData(
                    tile: metalTile,
                    forKey: key
                )
                if onMetalingTileEnd.count > 2 {
                    print("Warning. onMetalingTileEnd has ", onMetalingTileEnd.count, " handlers.")
                }
                for handler in onMetalingTileEnd {
                    handler(tile)
                }
            }
        }
    }
    
    func getMetalTile(tile: Tile) -> MetalTile? {
        return memoryMetalTile.getTile(forKey: tile.key())
    }
    
    func requestMetalTile(tile: Tile) {
        mapNeedsTile.please(tile: tile)
    }
}
