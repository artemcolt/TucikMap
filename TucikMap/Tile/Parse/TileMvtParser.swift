//
//  MVTTileParser.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import Metal
import Foundation
import MVTTools
import GISTools
import SwiftEarcut


class TileMvtParser {
    let device: MTLDevice
    let determineFeatureStyle: DetermineFeatureStyle
    
    // Parse
    let parsePolygon: ParsePolygon = ParsePolygon()
    let localTileBounds: BoundingBox!
    
    
    init(device: MTLDevice, determineFeatureStyle: DetermineFeatureStyle) {
        self.device = device
        self.determineFeatureStyle = determineFeatureStyle
        let tileExtent = Double(Settings.tileExtent)
        localTileBounds = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: tileExtent, longitude: tileExtent)
        )
    }
    
    func parse(zoom: Int, x: Int, y: Int, mvtData: Data) -> ParsedTile {
        let tile = VectorTile(data: mvtData, x: x, y: y, z: zoom, projection: .noSRID, indexed: .hilbert)!
        
        let readingStageResult = readingStage(tile: tile)
        let unificationResult = unificationStage(readingStageResult: readingStageResult)
        
        return ParsedTile(
            drawingPolygonData: unificationResult.drawingPolygonData,
            zoom: zoom,
            x: x,
            y: y
        )
    }
    
    private func tryParsePolygon(geometry: GeoJsonGeometry) -> ParsedPolygon? {
        if geometry.type != .polygon {return nil}
        guard let polygon = geometry as? Polygon else {return nil}
        guard let clippedPolygon = polygon.clipped(to: localTileBounds) else {
            return nil
        }
        return parsePolygon.parse(polygon: clippedPolygon.coordinates)
    }
    
    private func tryParseMultiPolygon(geometry: GeoJsonGeometry) -> [ParsedPolygon]? {
        if geometry.type != .multiPolygon {return nil}
        guard let multiPolygon = geometry as? MultiPolygon else { return nil }
        guard let clippedMultiPolygon = multiPolygon.clipped(to: localTileBounds) else {
            return nil
        }
        var parsedPolygons: [ParsedPolygon] = []
        for polygon in clippedMultiPolygon.coordinates {
            guard let parsedPolygon = parsePolygon.parse(polygon: polygon) else { continue }
            parsedPolygons.append(parsedPolygon)
        }
        if parsedPolygons.isEmpty { return nil}
        
        return parsedPolygons
    }
    
    func readingStage(tile: VectorTile) -> ReadingStageResult {
        var polygonByStyle: [UInt8: [ParsedPolygon]] = [:]
        for layerName in tile.layerNames {
            guard let features = tile.features(for: layerName) else { continue }
            
            features.forEach { feature in
                let style = determineFeatureStyle.determine(data: DetFeatureStyleData(layerName: layerName))
                let styleKey = style.key
                if styleKey == 0 {
                    // none defineded style
                    return
                }
                
                // Process each feature
                let geometry = feature.geometry
                
                if let parsed = tryParsePolygon(geometry: geometry) { polygonByStyle[styleKey, default: []].append(parsed) }
                if let parsed = tryParseMultiPolygon(geometry: geometry) { polygonByStyle[styleKey, default: []].append(contentsOf: parsed)}
            }
        }
        
        return ReadingStageResult(
            polygonByStyle: polygonByStyle.filter { $0.value.isEmpty == false }
        )
    }
    
    func unificationStage(readingStageResult: ReadingStageResult) -> UnificationStageResult {
        var drawingPolygonData: [UInt8 : DrawingPolygonData] = [:]
        let polygonByStyle = readingStageResult.polygonByStyle
        
        // Iterate through each style and its associated polygons
        for (style, polygons) in polygonByStyle {
            var unifiedVertices: [SIMD2<Float>] = []
            var unifiedIndices: [UInt16] = []
            var currentVertexOffset: UInt16 = 0
            
            // Process each polygon for the current style
            for polygon in polygons {
                // Append vertices to unified array
                unifiedVertices.append(contentsOf: polygon.vertices)
                
                // Adjust indices for the current polygon and append
                let adjustedIndices = polygon.indices.map { index in
                    return index + currentVertexOffset
                }
                unifiedIndices.append(contentsOf: adjustedIndices)
                
                // Update vertex offset for the next polygon
                currentVertexOffset += UInt16(polygon.vertices.count)
            }
            
            let verticesBuffer = device.makeBuffer(
                bytes: unifiedVertices,
                length: unifiedVertices.count * MemoryLayout<SIMD2<Float>>.size,
                options: .storageModeShared)!
            let indicesBuffer = device.makeBuffer(
                bytes: unifiedIndices,
                length: unifiedIndices.count * MemoryLayout<UInt16>.size,
                options: .storageModeShared)!
            
            // Create DrawingPolygonData for the current style
            let polygonData = DrawingPolygonData(
                vertices: unifiedVertices,
                indices: unifiedIndices,
                indicesBuffer: indicesBuffer,
                verticesBuffer: verticesBuffer
            )
            
            drawingPolygonData[style] = polygonData
        }
        return UnificationStageResult(drawingPolygonData: drawingPolygonData)
    }
}
