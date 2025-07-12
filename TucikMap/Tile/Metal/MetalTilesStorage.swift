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
    private let onMetalingTileEnd: (Tile) -> Void
    private let textTools: TextTools
    
    private let metalDevice: MTLDevice
    private var filterTiles: [Tile] = []
    
    init(
        determineStyle: DetermineFeatureStyle,
        metalDevice: MTLDevice,
        textTools: TextTools,
        onMetalingTileEnd: @escaping (Tile) -> Void
    ) {
        self.textTools = textTools
        self.metalDevice = metalDevice
        self.onMetalingTileEnd = onMetalingTileEnd
        memoryMetalTile = MemoryMetalTileCache(maxCacheSizeInBytes: Settings.maxCachedTilesMemory)
        tileParser = TileMvtParser(determineFeatureStyle: determineStyle)
        mapNeedsTile = MapNeedsTile(onComplete: onTileComplete)
    }
    
    private func onTileComplete(data: Data?, tile: Tile) {
        guard let data = data else { return }
        
        if filterTiles.contains(where: { t in t.key() == tile.key()}) {
            if Settings.debugAssemblingMap { print("Parsing and metaling \(tile)") }
            Task {
                let parsedTile = await tileParser.parse(
                    tile: tile,
                    mvtData: data,
                    boundingBox: BoundingBox(
                        southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
                        northEast: Coordinate3D(latitude: Double(Settings.tileExtent), longitude: Double(Settings.tileExtent))
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
                
                //var roadLabelsMetal: [RoadLabelMetal] = []
                let font = textTools.robotoFont.regularFont
                let roadLabels = parsedTile.roadLabels
                
                
                let textLabels = textTools.mapLabelsAssembler.assemble(
                    lines: parsedTile.textLabels.map { label in MapLabelsAssembler.TextLineData(
                        text: label.nameEn,
                        scale: label.scale,
                        localPosition: label.localPosition,
                        id: label.id,
                        sortRank: label.sortRank
                    )},
                    font: textTools.robotoFont.boldFont
                )
                
                let metalGeoLabels = MetalGeoLabels(
                    tile: tile,
                    textLabels: textLabels
                )
                
                let metalTile = MetalTile(
                    tile: tile,
                    tile2dBuffers: tile2dBuffers,
                    tile3dBuffers: tile3dBuffers
                )
                
                await MainActor.run {
                    let key = tile.key()
                    self.memoryMetalTile.setTile(metalTile, forKey: key)
                    self.memoryMetalTile.setGeoLabelsTile(metalGeoLabels, forKey: key)
                    self.onMetalingTileEnd(tile)
                }
            }
        }
    }
    
    func setupTilesFilter(filterTiles: [Tile]) {
        self.filterTiles = filterTiles
    }
    
    func getMetalTile(tile: Tile) -> MetalTile? {
        return memoryMetalTile.getTile(forKey: tile.key())
    }
    
    func getMetalGeoLabels(tile: Tile) -> MetalGeoLabels? {
        return memoryMetalTile.getTileGeoLabels(forKey: tile.key())
    }
    
    func requestMetalTile(tile: Tile) {
        mapNeedsTile.please(tile: tile)
    }
}
