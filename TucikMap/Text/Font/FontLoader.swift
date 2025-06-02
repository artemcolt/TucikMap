//
//  FontLoader.swift
//  TucikMap
//
//  Created by Artem on 6/2/25.
//

import MetalKit
import Foundation

class FontLoader {
    private let textureLoader: MTKTextureLoader!
    private let decoder: JSONDecoder
    
    init(metalDevice: MTLDevice) {
        textureLoader = MTKTextureLoader(device: metalDevice)
        decoder = JSONDecoder()
    }
    
    func load(fontName: String) -> Font {
        let atlasURL = Bundle.main.url(forResource: fontName, withExtension: "png")!
        let jsonURL = Bundle.main.url(forResource: fontName, withExtension: "json")!
        let fontData = loadFontData(jsonURL: jsonURL)!
        let atlas = loadFontAtlas(atlasURL: atlasURL)!
        return Font(atlasTexture: atlas, fontData: fontData)
    }
    
    private func loadFontData(jsonURL: URL) -> FontData? {
        do {
            let data = try Data(contentsOf: jsonURL)
            return try decoder.decode(FontData.self, from: data)
        } catch {
            print("Ошибка чтения JSON: \(error)")
        }
        return nil
    }
    
    private func loadFontAtlas(atlasURL: URL) -> MTLTexture? {
        do {
            return try textureLoader.newTexture(URL: atlasURL, options: [
                .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                .textureStorageMode: MTLStorageMode.private.rawValue
            ])
        } catch {
            print("Ошибка загрузки атласа шрифта: \(error)")
        }
        return nil
    }
}
