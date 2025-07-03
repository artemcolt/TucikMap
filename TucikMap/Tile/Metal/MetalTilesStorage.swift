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
                
                
                let vertices3DBuffer = parsedTile.drawing3dPolygon.vertices.isEmpty ? nil : metalDevice.makeBuffer(
                    bytes: parsedTile.drawing3dPolygon.vertices,
                    length: parsedTile.drawing3dPolygon.vertices.count * MemoryLayout<Polygon3dPipeline.VertexIn>.stride
                )
                let indices3DBuffer = parsedTile.drawing3dPolygon.indices.isEmpty ? nil : metalDevice.makeBuffer(
                    bytes: parsedTile.drawing3dPolygon.indices,
                    length: parsedTile.drawing3dPolygon.indices.count * MemoryLayout<UInt32>.stride
                )
                let styles3DBuffer = metalDevice.makeBuffer(
                    bytes: parsedTile.styles3d,
                    length: parsedTile.styles3d.count * MemoryLayout<TilePolygonStyle>.stride
                )!
                
                
                let builtText = textTools.mapLabelsAssembler.assemble(
                    lines: parsedTile.textLabels.map { label in MapLabelsAssembler.TextLineData(
                        text: label.nameEn,
                        scale: label.scale,
                        localPosition: label.localPosition
                    )},
                    font: textTools.robotoFont.boldFont
                )
                
                
                let metalTile = MetalTile(
                    verticesBuffer: verticesBuffer,
                    indicesBuffer: indicesBuffer,
                    indicesCount: parsedTile.drawingPolygon.indices.count,
                    stylesBuffer: stylesBuffer,
                    tile: tile,
                    textLabels: builtText,
                    textLabelsIds: parsedTile.textLabels.map { label in label.id },
                    
                    vertices3DBuffer: vertices3DBuffer,
                    indices3DBuffer: indices3DBuffer,
                    styles3DBuffer: styles3DBuffer,
                    indices3DCount: parsedTile.drawing3dPolygon.indices.count,
                )
                
                await MainActor.run {
                    self.memoryMetalTile.setTile(metalTile, forKey: tile.key())
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
    
    func requestMetalTile(tile: Tile) {
        mapNeedsTile.please(tile: tile)
    }
}
