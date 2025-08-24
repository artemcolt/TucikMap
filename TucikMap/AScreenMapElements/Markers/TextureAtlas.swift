//
//  TextureAtlas.swift
//  TucikMap
//
//  Created by Artem on 8/23/25.
//

import MetalKit

class TextureAtlas {
    struct Element {
        let startUV: SIMD2<Float>
    }
    
    private let atlasSize: Int
    private let elementInTextureSize: Int
    private let sizeOfAtlas: Int
    private let atlasBorderCount: Int
    private var elements: [Element?]
    let atlasTexture: MTLTexture
    let uvSize: Float
    
    
    init(metalDevice: MTLDevice, atlasSize: Int = 256, elementInTextureSize: Int = 64) {
        self.atlasSize = atlasSize
        self.elementInTextureSize = elementInTextureSize
        self.atlasBorderCount = atlasSize / elementInTextureSize
        self.sizeOfAtlas = atlasBorderCount * atlasBorderCount
        self.uvSize = 1.0 / Float(atlasBorderCount)
        self.elements = Array(repeating: nil, count: sizeOfAtlas)
        
        let atlasTextureDescriptor = MTLTextureDescriptor()
        atlasTextureDescriptor.pixelFormat = .bgra8Unorm
        atlasTextureDescriptor.width = atlasSize
        atlasTextureDescriptor.height = atlasSize
        atlasTextureDescriptor.usage = [.shaderRead]
        atlasTexture = metalDevice.makeTexture(descriptor: atlasTextureDescriptor)!
    }
    
    func getElement(index: Int) -> Element? {
        return elements[index]
    }
    
    func addToAtlas(image: UIImage) -> Int? {
        // Find the first available slot
        guard let index = elements.firstIndex(where: { $0 == nil }) else {
            // Atlas is full; handle error as needed (e.g., print or throw)
            return nil
        }
        
        let resizedImage: UIImage = ImageUtils.resizeIfNeeded(image: image, targetSize: elementInTextureSize)
        
        // Get pixel data from resized UIImage
        guard let cgImage = resizedImage.cgImage else {
            // Handle invalid image
            return nil
        }
        
        let res = ImageUtils.rgbaTobgra8Unorm(cgImage: cgImage, targetSize: elementInTextureSize)
        let pixelData = res.pixelData
        let bytesPerRow = res.bytesPerRow
        
        // Calculate position in atlas
        let borderCount = atlasBorderCount
        let row = index / borderCount
        let col = index % borderCount
        let x = col * elementInTextureSize
        let y = row * elementInTextureSize
        
        // Update texture
        pixelData.withUnsafeBytes { bytesPtr in
            let region = MTLRegion(origin: MTLOrigin(x: x, y: y, z: 0), size: MTLSize(width: elementInTextureSize, height: elementInTextureSize, depth: 1))
            atlasTexture.replace(region: region, mipmapLevel: 0, withBytes: bytesPtr.baseAddress!, bytesPerRow: bytesPerRow)
        }
        
        // Calculate UV (normalized 0-1, bottom-left)
        let u = Float(x) / Float(atlasSize)
        var v = Float(y) / Float(atlasSize)
        v = 1.0 - (v + uvSize)
        let startUV = SIMD2<Float>(u, v)
        
        // Save marker
        elements[index] = Element(startUV: startUV)
        return index
    }
}
