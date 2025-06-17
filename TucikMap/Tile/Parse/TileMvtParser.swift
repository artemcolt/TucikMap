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
    let giveMeId: GiveMeId = GiveMeId()
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
        
        let readingStageResult = readingStage(tile: vectorTile, boundingBox: boundingBox, tileCoords: tile)
        let unificationResult = unificationStage(readingStageResult: readingStageResult)
        
        return ParsedTile(
            drawingPolygon: unificationResult.drawingPolygon,
            styles: unificationResult.styles,
            tile: tile,
            textLabels: readingStageResult.textLabels
        )
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
    
    private func tryParseLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Double) -> [ParsedLineRawVertices]? {
        if geometry.type != .lineString {return nil}
        guard let line = geometry as? LineString else {return nil}
        guard let clippedLine = line.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: clippedLine, width: width)
    }
    
    private func tryParseMultiLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Double) -> [ParsedLineRawVertices]? {
        if geometry.type != .multiLineString {return nil}
        guard let multiLine = geometry as? MultiLineString else {return nil}
        guard let clippedMultiLine = multiLine.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: clippedMultiLine, width: width)
    }
    
    private func parseLines(multiLine: MultiLineString, width: Double) -> [ParsedLineRawVertices] {
        var parsed: [ParsedLineRawVertices] = []
        for line in multiLine.lineStrings {
            let coordinates = line.coordinates
            guard coordinates.count >= 2 else {continue}
            let parsedLine = parseLine.parseRaw(line: coordinates, width: width)
            parsed.append(parsedLine)
        }
        return parsed
    }
    
    private func tryParseTextLabels(
        geometry: GeoJsonGeometry,
        boundingBox: BoundingBox,
        tileCoords: Tile,
        properties: [String: Sendable]) -> ParsedTextLabel?
    {
        if geometry.type != .point {return nil}
        guard let point = geometry as? Point else {return nil}
        let x = point.coordinate.x
        let y = point.coordinate.y
        guard x > 0 && x < Double(Settings.tileExtent) && y > 0 && y < Double(Settings.tileExtent) else { return nil }
        guard let filterTextResult = determineFeatureStyle.filterTextLabels(properties: properties, tile: tileCoords) else { return nil }
        let coordinate = NormalizeLocalCoords.normalize(coord: SIMD2<Double>(x, y))
        return ParsedTextLabel(
            id: giveMeId.forTextLabel(),
            localPosition: coordinate,
            nameEn: filterTextResult.text,
            scale: filterTextResult.scale,
            sortRank: filterTextResult.sortRank
        )
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
    
    func readingStage(tile: VectorTile, boundingBox: BoundingBox, tileCoords: Tile) -> ReadingStageResult {
        var polygonByStyle: [UInt8: [ParsedPolygon]] = [:]
        var rawLineByStyle: [UInt8: [ParsedLineRawVertices]] = [:]
        var styles: [UInt8: FeatureStyle] = [:]
        var textLabels: [ParsedTextLabel] = []
        
        for layerName in tile.layerNames {
            guard let features = tile.features(for: layerName) else { continue }
            
            features.forEach { feature in
                let properties = feature.properties
                
                let geometry = feature.geometry
                if let parsed = tryParseTextLabels(geometry: geometry, boundingBox: boundingBox, tileCoords: tileCoords, properties: properties) {
                    textLabels.append(parsed)
                }
                
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
        
        textLabels.sort(by: { label1, label2 in
            return label1.sortRank < label2.sortRank
        }) // сортировка по возрастанию
        
        return ReadingStageResult(
            polygonByStyle: polygonByStyle.filter { $0.value.isEmpty == false },
            rawLineByStyle: rawLineByStyle.filter { $0.value.isEmpty == false },
            styles: styles,
            textLabels: textLabels
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
