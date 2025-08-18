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
    private let giveMeId                    : GiveMeId = GiveMeId()
    private let determineFeatureStyle       : DetermineFeatureStyle
    private let mapSettings                 : MapSettings
    
    private let parsePolygon                : ParsePolygon = ParsePolygon()
    private let parseLine                   : ParseLine = ParseLine()
    private let parseBuilding               : ParseBuilding = ParseBuilding()
    
    private var parsedCountTest             = 0
    
    
    init(determineFeatureStyle: DetermineFeatureStyle, mapSettings: MapSettings) {
        self.determineFeatureStyle = determineFeatureStyle
        self.mapSettings = mapSettings
    }
    
    func parse(
        tile: Tile,
        mvtData: Data,
        boundingBox: BoundingBox
    ) async -> ParsedTile {
        let x = tile.x
        let y = tile.y
        let z = tile.z
        let vectorTile = VectorTile(data: mvtData, x: x, y: y, z: z, projection: .noSRID, indexed: .hilbert)!
        
        let readingStageResult = await readingStage(tile: vectorTile, boundingBox: boundingBox, tileCoords: tile)
        let unificationResult = unificationStage(readingStageResult: readingStageResult)
        let unification3DResult = unification3DStage(readingStageResult: readingStageResult)
        
        return ParsedTile(
            drawingPolygon: unificationResult.drawingPolygon,
            styles: unificationResult.styles,
            tile: tile,
            textLabels: readingStageResult.textLabels,
            roadLabels: readingStageResult.roadLabels,
            
            drawing3dPolygon: unification3DResult.drawingPolygon,
            styles3d: unification3DResult.styles
        )
    }
    
    private func tryParsePolygonBuilding(geometry: GeoJsonGeometry, boundingBox: BoundingBox, height: Double, tileExtent: Double) -> Parsed3dPolygon? {
        if geometry.type != .polygon {return nil}
        guard let polygon = geometry as? Polygon else {return nil}
//        guard let clippedPolygon = polygon.clipped(to: boundingBox) else {
//            return nil
//        }
        return parseBuilding.parseBuilding(polygon: polygon.coordinates, parsePolygon: parsePolygon, height: height, tileExtent: tileExtent)
    }
    
    private func tryParseMultiPolygonBuilding(geometry: GeoJsonGeometry, boundingBox: BoundingBox, height: Double, tileExtent: Double) -> [Parsed3dPolygon]? {
        if geometry.type != .multiPolygon {return nil}
        guard let multiPolygon = geometry as? MultiPolygon else { return nil }
//        guard let clippedMultiPolygon = multiPolygon.clipped(to: boundingBox) else {
//            return nil
//        }
        var parsedBuidlings: [Parsed3dPolygon] = []
        for polygon in multiPolygon.coordinates {
            guard let parsedBuilding = parseBuilding.parseBuilding(polygon: polygon, parsePolygon: parsePolygon, height: height, tileExtent: tileExtent) else { continue }
            parsedBuidlings.append(parsedBuilding)
        }
        if parsedBuidlings.isEmpty { return nil}
        
        return parsedBuidlings
    }
    
    private func tryParsePolygon(geometry: GeoJsonGeometry, boundingBox: BoundingBox) -> ParsedPolygon? {
        if geometry.type != .polygon {return nil}
        guard let polygon = geometry as? Polygon else {return nil}
        guard let clippedPolygon = polygon.clipped(to: boundingBox) else {
            return nil
        }
        let tileExtent = Double(mapSettings.getMapCommonSettings().getTileExtent())
        return parsePolygon.parse(polygon: clippedPolygon.coordinates, tileExtent: tileExtent)
    }
    
    private func tryParseMultiPolygon(geometry: GeoJsonGeometry, boundingBox: BoundingBox) -> [ParsedPolygon]? {
        if geometry.type != .multiPolygon {return nil}
        guard let multiPolygon = geometry as? MultiPolygon else { return nil }
        guard let clippedMultiPolygon = multiPolygon.clipped(to: boundingBox) else {
            return nil
        }
        let tileExtent = Double(mapSettings.getMapCommonSettings().getTileExtent())
        var parsedPolygons: [ParsedPolygon] = []
        for polygon in clippedMultiPolygon.coordinates {
            guard let parsedPolygon = parsePolygon.parse(polygon: polygon, tileExtent: tileExtent) else { continue }
            parsedPolygons.append(parsedPolygon)
        }
        if parsedPolygons.isEmpty { return nil}
        
        return parsedPolygons
    }
    
    private func tryParseLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Double) -> [ParsedLineRawVertices]? {
        if geometry.type != .lineString {return nil}
        guard let line = geometry as? LineString else {return nil}
        
        //guard let clippedLine = line.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: MultiLineString([line], calculateBoundingBox: false)!, width: width)
    }
    
    private func tryParseMultiLine(geometry: GeoJsonGeometry, boundingBox: BoundingBox, width: Double) -> [ParsedLineRawVertices]? {
        if geometry.type != .multiLineString {return nil}
        guard let multiLine = geometry as? MultiLineString else {return nil}
        //guard let clippedMultiLine = multiLine.clipped(to: boundingBox) else {return nil}
        return parseLines(multiLine: multiLine, width: width)
    }
    
    private func parseLines(multiLine: MultiLineString, width: Double) -> [ParsedLineRawVertices] {
        let tileExtent = Double(mapSettings.getMapCommonSettings().getTileExtent())
        var parsed: [ParsedLineRawVertices] = []
        for line in multiLine.lineStrings {
            let coordinates = line.coordinates
            guard coordinates.count >= 2 else { continue }
            let parsedLine = parseLine.parseRaw(line: coordinates, width: width, tileExtent: tileExtent)
            parsed.append(parsedLine)
        }
        return parsed
    }
    
    private func tryParseRoadLine(geometry: GeoJsonGeometry, name: String, tileCoords: Tile) async -> ParsedRoadLabel? {
        if geometry.type != .lineString {return nil}
        guard let line = geometry as? LineString else {return nil}
        return await parseRoad(coordinates: line.coordinates, name: name, tileCoords: tileCoords)
    }
    
    private func tryParseRoadMultiLine(geometry: GeoJsonGeometry, name: String, tileCoords: Tile) async -> [ParsedRoadLabel]? {
        if geometry.type != .multiLineString {return nil}
        guard let multiLine = geometry as? MultiLineString else {return nil}
        var parsed: [ParsedRoadLabel] = []
        for line in multiLine.coordinates {
            guard let parsedRoad = await parseRoad(coordinates: line, name: name, tileCoords: tileCoords) else { continue }
            parsed.append(parsedRoad)
        }
        return parsed
    }
    
    private func parseRoad(coordinates: [Coordinate3D], name: String, tileCoords: Tile) async -> ParsedRoadLabel? {
        let tileExtent = Double(mapSettings.getMapCommonSettings().getTileExtent())
        var points: [SIMD2<Float>] = []
        points.reserveCapacity(coordinates.count)
        for coordinate in coordinates {
            let currentPoint = NormalizeLocalCoords.normalize(coord: SIMD2<Double>(coordinate.x, coordinate.y), tileExtent: tileExtent)
            points.append(SIMD2<Float>(Float(currentPoint.x), Float(currentPoint.y)))
        }
        
        var worldPathLen = Float(0);
        for i in 0..<points.count - 1 {
            let currentPosition = points[i];
            let nextPosition = points[i+1];
            let length = length(nextPosition - currentPosition);
            worldPathLen += length;
        }
        
        // Тут пытаюсь проверять в целом длину дороги и если она прям очень маленькая то нету смысла ее парсить
        // все равно на нее ничего не поместиться
        let filterRoadLenLabel = mapSettings.getMapCommonSettings().getFilterRoadLenLabel()
        if worldPathLen < filterRoadLenLabel {
            return nil
        }
        
        return ParsedRoadLabel(name: name, localPoints: points, pathLen: worldPathLen, id: await giveMeId.getIdForRoadLabel())
    }
    
    private func tryParseTextLabels(
        geometry: GeoJsonGeometry,
        boundingBox: BoundingBox,
        tileCoords: Tile,
        properties: [String: Sendable],
    ) async -> ParsedTextLabel? {
        if geometry.type != .point {return nil}
        guard let point = geometry as? Point else {return nil}
        let x = point.coordinate.x
        let y = point.coordinate.y
        let tileExtent = mapSettings.getMapCommonSettings().getTileExtent()
        guard x > 0 && x < Double(tileExtent) && y > 0 && y < Double(tileExtent) else { return nil }
        guard let filterTextResult = determineFeatureStyle.filterTextLabels(properties: properties, tile: tileCoords) else { return nil }
        guard let nameEn = properties["name_en"] as? String else {return nil}
        let coordinate = NormalizeLocalCoords.normalize(coord: SIMD2<Double>(x, y), tileExtent: Double(tileExtent))
        
        // здесь это нужно только чтобы id рассчитать
        // mapSize по идее любым может быть ВРОДЕ БЫ
        let panningPoint = tileCoords
            .getTilePointPanningCoordinates(normalizedX: coordinate.x, normalizedY: coordinate.y, mapSize: 1.0)
        let uniqueGeoLabelKey = UniqueGeoLabelKey(x: panningPoint.x, y: panningPoint.y, name: nameEn)
        
        return ParsedTextLabel(
            id: await giveMeId.getIdForLabel(uniqueGeoLabelKey: uniqueGeoLabelKey),
            localPosition: SIMD2<Float>(coordinate),
            nameEn: filterTextResult.text,
            scale: filterTextResult.scale,
            sortRank: filterTextResult.sortRank
        )
    }
    
    private func addBackground(polygonByStyle: inout [UInt8: [ParsedPolygon]], styles: inout [UInt8: FeatureStyle]) {
        let style = determineFeatureStyle.makeStyle(data: DetFeatureStyleData(
            layerName: "background",
            properties: [:],
            tile: Tile(x: 0, y: 0, z: 0))
        )
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
    
    private func addBorders(polygonByStyle: inout [UInt8: [ParsedPolygon]], styles: inout [UInt8: FeatureStyle]) {
        let style = determineFeatureStyle.makeStyle(data: DetFeatureStyleData(
            layerName: "border",
            properties: [:],
            tile: Tile(x: 0, y: 0, z: 0))
        )
        
        let thickness: Float = 0.01
        let inner: Float = 1.0 - thickness

        let topPolygon = ParsedPolygon(
            vertices: [
                SIMD2<Float>(-1, inner),
                SIMD2<Float>(1, inner),
                SIMD2<Float>(1, 1),
                SIMD2<Float>(-1, 1)
            ],
            indices: [
                0, 1, 2,
                0, 2, 3
            ]
        )

        let bottomPolygon = ParsedPolygon(
            vertices: [
                SIMD2<Float>(-1, -1),
                SIMD2<Float>(1, -1),
                SIMD2<Float>(1, -inner),
                SIMD2<Float>(-1, -inner)
            ],
            indices: [
                0, 1, 2,
                0, 2, 3
            ]
        )

        let leftPolygon = ParsedPolygon(
            vertices: [
                SIMD2<Float>(-1, -inner),
                SIMD2<Float>(-inner, -inner),
                SIMD2<Float>(-inner, inner),
                SIMD2<Float>(-1, inner)
            ],
            indices: [
                0, 1, 2,
                0, 2, 3
            ]
        )

        let rightPolygon = ParsedPolygon(
            vertices: [
                SIMD2<Float>(inner, -inner),
                SIMD2<Float>(1, -inner),
                SIMD2<Float>(1, inner),
                SIMD2<Float>(inner, inner)
            ],
            indices: [
                0, 1, 2,
                0, 2, 3
            ]
        )

        polygonByStyle[style.key] = [topPolygon, bottomPolygon, leftPolygon, rightPolygon]
        styles[style.key] = style
    }
    
    func readingStage(tile: VectorTile, boundingBox: BoundingBox, tileCoords: Tile) async -> ReadingStageResult {
        let tileExtent = Double(mapSettings.getMapCommonSettings().getTileExtent())
        
        var polygon3dByStyle: [UInt8: [Parsed3dPolygon]] = [:]
        
        var polygonByStyle: [UInt8: [ParsedPolygon]] = [:]
        var rawLineByStyle: [UInt8: [ParsedLineRawVertices]] = [:]
        
        var styles: [UInt8: FeatureStyle] = [:]
        var textLabels: [ParsedTextLabel] = []
        var roadLabels: [ParsedRoadLabel] = []
        
        for layerName in tile.layerNames {
            guard let features = tile.features(for: layerName) else { continue }
            
            for feature in features {
                let properties = feature.properties
                
                let geometry = feature.geometry
                if let parsed = await tryParseTextLabels(
                    geometry: geometry,
                    boundingBox: boundingBox,
                    tileCoords: tileCoords,
                    properties: properties
                ) {
                    textLabels.append(parsed)
                }
                
                let detStyleData = DetFeatureStyleData(
                    layerName: layerName,
                    properties: properties,
                    tile: tileCoords
                )
                let style = determineFeatureStyle.makeStyle(data: detStyleData)
                let styleKey = style.key
                if styleKey == 0 {
                    // none defineded style
                    printNotUsedStyleToSee(detFeatureStyleData: detStyleData)
                    continue
                }
                if styles[styleKey] == nil {
                    styles[styleKey] = style
                }
                
                // Process each feature
                let parseGeomStyleData = style.parseGeometryStyleData
                
                let buildingsFactor = mapSettings.getMapCommonSettings().getBuildingsFactor()
                let extrude = properties["extrude"] as? String == "true"
                if layerName == "building" && extrude {
                    let currentZ = tileCoords.z
                    let baseZoom = 16
                    let difference = currentZ - baseZoom
                    let factor = pow(2.0, Double(difference))
                    guard var height = properties["height"] as? Double else { continue }
                    height = height * buildingsFactor * factor
                    let _ = properties["min_height"] as? Double
                    if let parsed = tryParsePolygonBuilding(geometry: geometry, boundingBox: boundingBox, height: height, tileExtent: tileExtent) {
                        polygon3dByStyle[styleKey, default: []].append(parsed)
                    }
                    if let parsed = tryParseMultiPolygonBuilding(geometry: geometry, boundingBox: boundingBox, height: height, tileExtent: tileExtent) {
                        polygon3dByStyle[styleKey, default: []].append(contentsOf: parsed)
                    }
                    continue
                }
                
                let renderOnlyRoadsArray = mapSettings.getMapDebugSettings().getRenderOnlyRoadsArray()
                let renderRoadArrayFromTo = mapSettings.getMapDebugSettings().getRenderRoadArrayFromTo()
                let name = properties["name_en"] as? String
                if layerName == "road" && name != nil {
                    let testCondition = renderOnlyRoadsArray.contains(name!) || renderOnlyRoadsArray.isEmpty
                    let fromToTestCond = renderRoadArrayFromTo.isEmpty ||
                        (renderRoadArrayFromTo[0] <= parsedCountTest && parsedCountTest <= renderRoadArrayFromTo[1])
                    if testCondition {
                        if fromToTestCond {
                            if let parsed = await tryParseRoadLine(geometry: geometry, name: name ?? "no street name", tileCoords: tileCoords) {
                                roadLabels.append(parsed)
                            }
                            if let parsed = await tryParseRoadMultiLine(geometry: geometry, name: name ?? "no street name", tileCoords: tileCoords) {
                                roadLabels.append(contentsOf: parsed)
                            }
                        }
                        parsedCountTest += 1
                    }
                }
                
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
        
        if mapSettings.getMapDebugSettings().getAddTestBorders() {
            addBorders(polygonByStyle: &polygonByStyle, styles: &styles)
        }
        
        textLabels.sort(by: { label1, label2 in
            return label1.sortRank < label2.sortRank
        }) // сортировка по возрастанию
        
        return ReadingStageResult(
            polygon3dByStyle: polygon3dByStyle.filter { $0.value.isEmpty == false },
            polygonByStyle: polygonByStyle.filter { $0.value.isEmpty == false },
            rawLineByStyle: rawLineByStyle.filter { $0.value.isEmpty == false },
            styles: styles,
            textLabels: textLabels,
            roadLabels: roadLabels
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
    
    func unification3DStage(readingStageResult: ReadingStageResult) -> Unification3DStageResult {
        let polygon3dByStyle = readingStageResult.polygon3dByStyle
        
        var unifiedVertices: [Polygon3dPipeline.VertexIn] = []
        var unifiedIndices: [UInt32] = []
        var currentVertexOffset: UInt32 = 0
        var styles: [TilePolygonStyle] = []
        
        var styleBufferIndex: simd_uchar1 = 0
        for styleKey in readingStageResult.styles.keys.sorted() {
            if let polygons = polygon3dByStyle[styleKey] {
                // Process each polygon for the current style
                for polygon in polygons {
                    
                    var shaderVertices: [Polygon3dPipeline.VertexIn] = []
                    shaderVertices.reserveCapacity(polygon.vertices.count)
                    for i in 0..<polygon.vertices.count {
                        let vertex = polygon.vertices[i]
                        let normal = polygon.normals[i]
                        shaderVertices.append(Polygon3dPipeline.VertexIn(
                            position: vertex,
                            normal: normal,
                            styleIndex: styleBufferIndex
                        ))
                    }
                    
                    // Append vertices to unified array
                    unifiedVertices.append(contentsOf: shaderVertices)
                    
                    // Adjust indices for the current polygon and append
                    let adjustedIndices = polygon.indices.map { index in
                        return index + currentVertexOffset
                    }
                    unifiedIndices.append(contentsOf: adjustedIndices)
                    
                    // Update vertex offset for the next polygon
                    currentVertexOffset += UInt32(polygon.vertices.count)
                }
            }
            
            let style = readingStageResult.styles[styleKey]!
            styles.append(TilePolygonStyle(color: style.color))
            styleBufferIndex += 1
        }
        
        return Unification3DStageResult(
            drawingPolygon: Drawing3dPolygonBytes(
                vertices: unifiedVertices,
                indices: unifiedIndices
            ),
            styles: styles
        )
    }
    
    private func printNotUsedStyleToSee(detFeatureStyleData: DetFeatureStyleData) {
        if mapSettings.getMapDebugSettings().getPrintNotUsedStyle() {
            let filterNotUsedLayernName = mapSettings.getMapDebugSettings().getFilterNotUsedLayernName()
            if filterNotUsedLayernName.isEmpty == false && detFeatureStyleData.layerName.contains(filterNotUsedLayernName) == false {
                return
            }
            print(detFeatureStyleData)
        }
    }
}
