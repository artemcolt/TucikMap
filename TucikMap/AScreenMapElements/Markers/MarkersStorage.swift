//
//  MarkersStorage.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class MarkersStorage {
    struct Marker {
        let atlasElementIndex: Int
        let size: Float
        let latLonDegrees: SIMD2<Double>
    }
    
    let markersGlobeBuffer: MTLBuffer
    let markersMetaGlobeBuffer: MTLBuffer
    let markersFlatBuffer: MTLBuffer
    let markersMetaFlatBuffer: MTLBuffer
    let textureAtlas: TextureAtlas
    
    private(set) var markers: [Marker] = []
    private(set) var verticesCountGlobe: Int = 0
    private(set) var verticesCountFlat: Int = 0
    
    init(metalDevice: MTLDevice, mapSettings: MapSettings, cameraStorage: CameraStorage) {
        textureAtlas = TextureAtlas(metalDevice: metalDevice)
        
        let maxMarkersVisible = mapSettings.getMapCommonSettings().getMaxMarkersVisible()
        markersGlobeBuffer = metalDevice.makeBuffer(length: MemoryLayout<GlobeMarkersPipeline.MarkerVertex>.stride * 6 * maxMarkersVisible)!
        markersMetaGlobeBuffer = metalDevice.makeBuffer(length: MemoryLayout<GlobeMarkersPipeline.MapMarkerMeta>.stride * maxMarkersVisible)!
        
        markersFlatBuffer = metalDevice.makeBuffer(length: MemoryLayout<MarkersPipeline.MarkerVertex>.stride * 6 * maxMarkersVisible)!
        markersMetaFlatBuffer = metalDevice.makeBuffer(length: MemoryLayout<MarkersPipeline.MapMarkerMeta>.stride * maxMarkersVisible)!
        
        let uiImage = ImageUtils.loadUIImage(name: "3dicons-3d-coin-dynamic-color", fileExt: "png")!
        // TODO
        // там в шейдере x - это longitude а y это latitude
        // надо будет потом привести к общему виду Разобраться че к чему
        //addMarker(image: uiImage, size: 200, latLonDegrees: Locations.russia.coordinate)
        //refresh()
    }
    
    private func addMarker(image: UIImage, size: Float, latLonDegrees: SIMD2<Double>) {
        guard let atlasElementIndex = textureAtlas.addToAtlas(image: image) else { return }
        markers.append(Marker(atlasElementIndex: atlasElementIndex,
                              size: size,
                              latLonDegrees: latLonDegrees))
    }
    
    func refresh() {
        refreshFlat()
        refreshGlobe()
    }
    
    private func refreshGlobe() {
        var markerVertices: [GlobeMarkersPipeline.MarkerVertex] = []
        var markersMeta: [GlobeMarkersPipeline.MapMarkerMeta] = []
        
        let uvSize = textureAtlas.uvSize
        for marker in markers {
            guard let atlasEl = textureAtlas.getElement(index: marker.atlasElementIndex) else { continue }
            let startU = atlasEl.startUV.x
            let startV = atlasEl.startUV.y
            
            let endU = startU + uvSize
            let endV = startV + uvSize
            
            let vertices: [GlobeMarkersPipeline.MarkerVertex] = [
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, startV)), // left-bottom
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, startV)), // right-bottom
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, endV)), // right-top
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, startV)), // left-bottom
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, endV)), // right-top
                GlobeMarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, endV))  // left-top
            ]
            markerVertices.append(contentsOf: vertices)
            
            let coordinate = marker.latLonDegrees
            let latPos = MapMathUtils.latitudeDegreesToNormalized(latitudeDegrees: coordinate.x)
            let lonPos = MapMathUtils.longitudeDegreesToNormalized(longitudeDegrees: coordinate.y)
            let globePos = SIMD2<Double>(lonPos, latPos)
            markersMeta.append(GlobeMarkersPipeline.MapMarkerMeta(size: marker.size, globeNormalizedPosition: SIMD2<Float>(globePos)))
        }
        
        markersGlobeBuffer.contents().copyMemory(from: markerVertices,
                                            byteCount: MemoryLayout<GlobeMarkersPipeline.MarkerVertex>.stride * markerVertices.count)
        
        markersMetaGlobeBuffer.contents().copyMemory(from: markersMeta,
                                                     byteCount: MemoryLayout<GlobeMarkersPipeline.MapMarkerMeta>.stride * markersMeta.count)
        verticesCountGlobe = markerVertices.count
    }
    
    private func refreshFlat() {
        var markerVertices: [MarkersPipeline.MarkerVertex] = []
        var markersMeta: [MarkersPipeline.MapMarkerMeta] = []
        
        let uvSize = textureAtlas.uvSize
        for marker in markers {
            guard let atlasEl = textureAtlas.getElement(index: marker.atlasElementIndex) else { continue }
            let startU = atlasEl.startUV.x
            let startV = atlasEl.startUV.y
            
            let endU = startU + uvSize
            let endV = startV + uvSize
            
            let vertices: [MarkersPipeline.MarkerVertex] = [
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, startV)), // left-bottom
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, startV)), // right-bottom
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, endV)), // right-top
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, startV)), // left-bottom
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(endU, endV)), // right-top
                MarkersPipeline.MarkerVertex(texCoord: SIMD2<Float>(startU, endV))  // left-top
            ]
            markerVertices.append(contentsOf: vertices)
            markersMeta.append(MarkersPipeline.MapMarkerMeta(size: marker.size))
        }
        
        markersFlatBuffer.contents().copyMemory(from: markerVertices,
                                                byteCount: MemoryLayout<MarkersPipeline.MarkerVertex>.stride * markerVertices.count)
        
        markersMetaFlatBuffer.contents().copyMemory(from: markersMeta,
                                                    byteCount: MemoryLayout<MarkersPipeline.MapMarkerMeta>.stride * markersMeta.count)
        verticesCountFlat = markerVertices.count
    }
}
