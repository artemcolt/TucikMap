//
//  ImageUtils.swift
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

import MetalKit

class ImageUtils {
    static func resizeIfNeeded(image: UIImage, targetSize: Int) -> UIImage {
        // Resize image if necessary
        let targetSize = CGSize(width: targetSize, height: targetSize)
        let resizedImage: UIImage
        if image.size != targetSize {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            resizedImage = renderer.image { ctx in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        } else {
            resizedImage = image
        }
        return resizedImage
    }
    
    struct RgbaTobgra8UnormResult {
        let pixelData: [UInt8]
        let bytesPerRow: Int
    }
    
    static func rgbaTobgra8Unorm(cgImage: CGImage, targetSize: Int) -> RgbaTobgra8UnormResult {
        let width = targetSize
        let height = targetSize
        let bytesPerRow = width * 4
        let dataLength = bytesPerRow * height
        let targetSize = CGSize(width: targetSize, height: targetSize)
        
        var pixelData = [UInt8](repeating: 0, count: dataLength)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        pixelData.withUnsafeMutableBytes { rawPtr in
            guard let context = CGContext(data: rawPtr.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
                // Handle context creation failure
                return
            }
            context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        }
        return RgbaTobgra8UnormResult(pixelData: pixelData, bytesPerRow: bytesPerRow)
    }
    
    static func loadUIImage(name: String, fileExt: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: fileExt) else {
            fatalError("Failed to find image file")
        }
        
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            fatalError("Failed to load UIImage")
        }
        
        return uiImage
    }
}
