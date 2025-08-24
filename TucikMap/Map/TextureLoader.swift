//
//  TextureLoader.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class TextureLoader {
    private let textureLoader: MTKTextureLoader
    
    init(metalDevice: MTLDevice) {
        textureLoader = MTKTextureLoader(device: metalDevice)
    }
    
    func loadMarkerImage(name: String, fileExt: String, width: Int, height: Int) -> MTLTexture {
        // Path to your image in the app bundle (e.g., "image.png")
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: fileExt) else {
            fatalError("Failed to find image file")
        }
        
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            fatalError("Failed to load UIImage")
        }
        
        // Resize the image to (using UIGraphics for simplicity)
        let targetSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Convert resized UIImage to CGImage
        let cgImage = resizedImage.cgImage!
        
        let texture = try! textureLoader.newTexture(cgImage: cgImage, options: [
                MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue)
            ])
        
        return texture
    }
}
