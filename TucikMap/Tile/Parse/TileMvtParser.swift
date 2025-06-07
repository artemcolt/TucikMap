//
//  MVTTileParser.swift
//  TucikMap
//
//  Created by Artem on 5/28/25.
//

import Foundation
import MVTTools
import GISTools
import SwiftEarcut
import MetalKit


class TileMvtParser {
    let determineFeatureStyle: DetermineFeatureStyle
    let mapSize = Settings.mapSize
    
    // Parse
    let parsePolygon: ParsePolygon = ParsePolygon()
    let parseLine: ParseLine = ParseLine()
    
    
    init(determineFeatureStyle: DetermineFeatureStyle) {
        self.determineFeatureStyle = determineFeatureStyle
    }
    
    func parse(
        tile: Tile,
        mvtData: Data,
        boundingBox: BoundingBox
    ) -> ParsedTile {
        let x = tile.x
        let y = tile.y
        let z = tile.z
        let vectorTile = VectorTile(data: mvtData, x: x, y: y, z: z, projection: .noSRID, indexed: .hilbert)!
        
        let readingStageResult = readingStage(tile: vectorTile, boundingBox: boundingBox)
        let unificationResult = unificationStage(readingStageResult: readingStageResult)
        let modelMatrix = createModelMatrix(tile: tile)
        
        return ParsedTile(
            drawingPolygon: unificationResult.drawingPolygon,
            styles: unificationResult.styles,
            modelMatrix: modelMatrix,
            tile: tile
        )
    }
    
    private func createModelMatrix(tile: Tile) -> matrix_float4x4 {
        let x = tile.x
        let y = tile.y
        let z = tile.z
        
        let zoomFactor = pow(2.0, Float(z))
        let lastTileCoord = Int(zoomFactor) - 1
        let tileSize = mapSize / zoomFactor
        let offsetX = Float(x) * tileSize - mapSize / 2.0 + tileSize / 2.0
        let offsetY = Float(lastTileCoord - y) * tileSize - mapSize / 2.0 + tileSize / 2.0
        let scaleX = tileSize / 2.0
        let scaleY = tileSize / 2.0
        return MatrixUtils.createTileModelMatrix(scaleX: scaleX, scaleY: scaleY, offsetX: offsetX, offsetY: offsetY)
    }
    
    private func tryParsePolygon(geometry: GeoJsonGeometry, boundingBox: BoundingBox) -> ParsedPolygon? {
        if geometry.type != .polygon {return nil}
        guard let polygon = geometry as? Polygon else {return nil}
        guard let clippedPolygon = polygon.clipped(to: boundingBox) else {
            return nil
        }
        return parsePolygon.parse(polygon: clippedPolygon.coordinates)
    }
    
    private func tryParseMultiPolygon(geometry: GeoJsonGeometry, boundingBox: BoundingBox) -> [ParsedPolygon]? {
        if geometry.type != .multiPolygon {return nil}
        guard let multiPolygon = geometry as? MultiPolygon else { return nil }
        guard let clippedMultiPolygon = multiPolygon.clipped(to: boundingBox) else {
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
    
    private func tryParseLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Float) -> [ParsedLineRawVertices]? {
        if geometry.type != .lineString {return nil}
        guard let line = geometry as? LineString else {return nil}
        guard let clippedLine = line.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: clippedLine, width: width)
    }
    
    private func tryParseMultiLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Float) -> [ParsedLineRawVertices]? {
        if geometry.type != .multiLineString {return nil}
        guard let multiLine = geometry as? MultiLineString else {return nil}
        guard let clippedMultiLine = multiLine.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: clippedMultiLine, width: width)
    }
    
    private func parseLines(multiLine: MultiLineString, width: Float) -> [ParsedLineRawVertices] {
        var parsed: [ParsedLineRawVertices] = []
        for line in multiLine.lineStrings {
            let coordinates = line.coordinates
            guard coordinates.count >= 2 else {continue}
            let parsedLine = parseLine.parseRaw(line: coordinates, width: width)
            parsed.append(parsedLine)
        }
        return parsed
    }
    
    private func addBackground(polygonByStyle: inout [UInt8: [ParsedPolygon]], styles: inout [UInt8: FeatureStyle]) {
        let style = determineFeatureStyle.makeStyle(data: DetFeatureStyleData(layerName: "background", properties: [:]))
        polygonByStyle[style.key] = [ParsedPolygon(
            vertices: [
                SIMD2<Float>(-1, -1),
                SIMD2<Float>(1, -1),
                SIMD2<Float>(1, 1),
                SIMD2<Float>(-1, 1)
            ],
            indices: [
                0, 1, 2,
                0, 2, 3
            ]
        )]
        styles[style.key] = style
    }
    
    func readingStage(tile: VectorTile, boundingBox: BoundingBox) -> ReadingStageResult {
        var polygonByStyle: [UInt8: [ParsedPolygon]] = [:]
        var rawLineByStyle: [UInt8: [ParsedLineRawVertices]] = [:]
        var styles: [UInt8: FeatureStyle] = [:]
        for layerName in tile.layerNames {
            guard let features = tile.features(for: layerName) else { continue }
            
            features.forEach { feature in
                let properties = feature.properties
                let detStyleData = DetFeatureStyleData(layerName: layerName, properties: properties)
                let style = determineFeatureStyle.makeStyle(data: detStyleData)
                let styleKey = style.key
                if styleKey == 0 {
                    // none defineded style
                    PrintStyleHelper.printNotUsedStyleToSee(detFeatureStyleData: detStyleData)
                    return
                }
                if styles[styleKey] == nil {
                    styles[styleKey] = style
                }
                
                // Process each feature
                let geometry = feature.geometry
                let parseGeomStyleData = style.parseGeometryStyleData
                
                if let parsed = tryParsePolygon(geometry: geometry,
                                                boundingBox: boundingBox
                ) {
                    polygonByStyle[styleKey, default: []].append(parsed)
                }
                if let parsed = tryParseMultiPolygon(geometry: geometry,
                                                     boundingBox: boundingBox
                ) {
                    polygonByStyle[styleKey, default: []].append(contentsOf: parsed)
                }
                if let parsed = tryParseLine(geometry: geometry,
                                             boundingBox: boundingBox,
                                             width: parseGeomStyleData.lineWidth
                ) { rawLineByStyle[styleKey, default: []].append(contentsOf: parsed) }
                if let parsed = tryParseMultiLine(geometry: geometry,
                                                  boundingBox: boundingBox,
                                                  width: parseGeomStyleData.lineWidth
                ) { rawLineByStyle[styleKey, default: []].append(contentsOf: parsed) }
            }
        }
        
        addBackground(polygonByStyle: &polygonByStyle, styles: &styles)
        
        return ReadingStageResult(
            polygonByStyle: polygonByStyle.filter { $0.value.isEmpty == false },
            rawLineByStyle: rawLineByStyle.filter { $0.value.isEmpty == false },
            styles: styles
        )
    }
    
    func unificationStage(readingStageResult: ReadingStageResult) -> UnificationStageResult {
        let polygonByStyle = readingStageResult.polygonByStyle
        let rawLineByStyle = readingStageResult.rawLineByStyle
        
        var unifiedVertices: [PolygonPipeline.VertexIn] = []
        var unifiedIndices: [UInt32] = []
        var currentVertexOffset: UInt32 = 0
        var styles: [TilePolygonStyle] = []
        
        var styleBufferIndex: simd_uchar1 = 0
        for styleKey in readingStageResult.styles.keys.sorted() {
            if let polygons = polygonByStyle[styleKey] {
                // Process each polygon for the current style
                for polygon in polygons {
                    // Append vertices to unified array
                    unifiedVertices.append(contentsOf: polygon.vertices.map {
                        position in PolygonPipeline.VertexIn(position: position, styleIndex: styleBufferIndex)
                    })
                    
                    // Adjust indices for the current polygon and append
                    let adjustedIndices = polygon.indices.map { index in
                        return index + currentVertexOffset
                    }
                    unifiedIndices.append(contentsOf: adjustedIndices)
                    
                    // Update vertex offset for the next polygon
                    currentVertexOffset += UInt32(polygon.vertices.count)
                }
            }
            
            if let rawLines = rawLineByStyle[styleKey] {
                for rawLine in rawLines {
                    // Append vertices to unified array
                    unifiedVertices.append(contentsOf: rawLine.vertices.map {
                        position in PolygonPipeline.VertexIn(position: position, styleIndex: styleBufferIndex)
                    })
                    
                    // Adjust indices for the current polygon and append
                    let adjustedIndices = rawLine.indices.map { index in
                        return index + currentVertexOffset
                    }
                    unifiedIndices.append(contentsOf: adjustedIndices)
                    
                    // Update vertex offset for the next polygon
                    currentVertexOffset += UInt32(rawLine.vertices.count)
                }
            }
            
            let style = readingStageResult.styles[styleKey]!
            styles.append(TilePolygonStyle(color: style.color))
            styleBufferIndex += 1
        }
        
        return UnificationStageResult(
            drawingPolygon: DrawingPolygonBytes(
                vertices: unifiedVertices,
                indices: unifiedIndices
            ),
            styles: styles
        )
    }
}
