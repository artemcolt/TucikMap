//
//  TileMapAssembler.swift
//  TucikMap
//
//  Created by Artem on 5/29/25.
//

import MetalKit

class TileMapAssembler {
    var device: MTLDevice
    var mapSize: Float
    var determineFeatureStyle: DetermineFeatureStyle
    
    init(device: MTLDevice, mapSize: Float, determineFeatureStyle: DetermineFeatureStyle) {
        self.device = device
        self.mapSize = mapSize
        self.determineFeatureStyle = determineFeatureStyle
    }
    
    func assemble(parsedTiles: [ParsedTile]) -> AssembledMap {
        // Group polygons by style
        var geometryByStyle: [UInt8: (vertices: [SIMD2<Float>], indices: [UInt32])] = [:]
        
        for tile in parsedTiles {
            let zoomFactor = pow(2.0, Float(tile.zoom))
            let lastTileCoord = Int(zoomFactor) - 1
            let tileSize = mapSize / zoomFactor
            let offsetX = Float(tile.x) * tileSize - mapSize / 2.0
            let offsetY = Float(lastTileCoord - tile.y) * tileSize - mapSize / 2.0
            
            for (style, polygonData) in tile.drawingPolygonData {
                var styleGeometry = geometryByStyle[style, default: (vertices: [], indices: [])]
                let vertexOffset = UInt32(styleGeometry.vertices.count)
                
                // Transform vertices
                let transformedVertices = polygonData.vertices.map { vertex in
                    let scaledX = vertex.x * tileSize / 2.0
                    let scaledY = vertex.y * tileSize / 2.0
                    return SIMD2<Float>(
                        x: scaledX + offsetX + tileSize / 2.0,
                        y: scaledY + offsetY + tileSize / 2.0
                    )
                }
                
                // Adjust indices for the new vertex offset
                let adjustedIndices = polygonData.indices.map { UInt32($0) + vertexOffset }
                
                // Append to the style's geometry
                styleGeometry.vertices.append(contentsOf: transformedVertices)
                styleGeometry.indices.append(contentsOf: adjustedIndices)
                geometryByStyle[style] = styleGeometry
            }
        }
        
        // Create Metal buffers for each style
        var assembledMapFeature: [AssembledMapFeature] = []
        
        for style in geometryByStyle.keys.sorted() {
            let geometry = geometryByStyle[style]!
            guard !geometry.vertices.isEmpty, !geometry.indices.isEmpty else { continue }
            
            // Create vertex buffer
            let vertexBuffer = device.makeBuffer(
                bytes: geometry.vertices,
                length: geometry.vertices.count * MemoryLayout<SIMD2<Float>>.stride,
                options: .storageModeShared
            )!
            
            // Create index buffer
            let indexBuffer = device.makeBuffer(
                bytes: geometry.indices,
                length: geometry.indices.count * MemoryLayout<UInt32>.stride,
                options: .storageModeShared
            )!
            
            assembledMapFeature.append(AssembledMapFeature(
                featureStyle: determineFeatureStyle.getStyle(key: style),
                verticesBuffer: vertexBuffer,
                indicesBuffer: indexBuffer,
                vertexCount: geometry.vertices.count,
                indexCount: geometry.indices.count,
                indexType: .uint32
            ))
        }
        
        return AssembledMap(polygonFeatures: assembledMapFeature)
    }
}
