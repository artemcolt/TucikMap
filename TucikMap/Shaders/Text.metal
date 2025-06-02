//
//  Text.metal
//  TucikMap
//
//  Created by Artem on 6/1/25.
//

#include <metal_stdlib>
using namespace metal;

// Структура для вершинного шейдера
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Структура для uniforms
struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
};

struct Glyph {
    float3 translation;
    float3 rotation;
    float scale;
};

// Вершинный шейдер
vertex VertexOut textVertexShader(VertexIn in [[stage_in]],
                                  constant Uniforms &uniforms [[buffer(1)]],
                                  constant Glyph* glyphs [[buffer(2)]],
                                  uint vertexID [[vertex_id]]
                                  ) {
    VertexOut out;
    Glyph glyph = glyphs[vertexID / 6];
    float3 t = glyph.translation;
    float scale = glyph.scale;
    
    float4x4 translationMatrix = float4x4(scale, 0.0, 0.0, 0.0,
                                          0.0, scale, 0.0, 0.0,
                                          0.0, 0.0, 1.0, 0.0,
                                          t.x, t.y, t.z, 1.0);
    
    // Применение матриц преобразования
    float4 position = translationMatrix * float4(in.position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * position;
    out.texCoord = in.texCoord;
    
    return out;
}

// Функция для вычисления MSDF расстояния
float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

// Фрагментный шейдер для MSDF рендеринга
fragment float4 textFragmentShader(VertexOut in [[stage_in]],
                                 texture2d<float> atlasTexture [[texture(0)]],
                                 sampler textureSampler [[sampler(0)]]) {
    // Чтение значения из MSDF атласа
    float4 msdf = atlasTexture.sample(textureSampler, in.texCoord);
    float sigDist = median(msdf.r, msdf.g, msdf.b) - 0.5;
    float opacity = clamp(sigDist/fwidth(sigDist) + 0.5, 0.0, 1.0);
    return float4(1.0, 0.0, 0.0, opacity);
}


