//
//  RoadLabel.metal
//  TucikMap
//
//  Created by Artem on 7/11/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};


vertex VertexOut roadLabelsVertexShader(VertexIn vertexIn [[stage_in]],
                                    constant Uniforms &uniforms [[buffer(1)]],
                                    constant float4x4& modelMatrix [[buffer(2)]],
                                    uint vertexID [[vertex_id]]
                                    ) {
    float2 position = vertexIn.position;
    float4 worldPosition = modelMatrix * float4(position, 0.0, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
   
    VertexOut out;
    out.position = clipPosition;
    out.texCoord = vertexIn.texCoord;
    return out;
}

fragment float4 roadLabelsFragmentShader(VertexOut in [[stage_in]],
                                     texture2d<float> atlasTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]]) {
    // Чтение значения из MSDF атласа
    float4 msdf = atlasTexture.sample(textureSampler, in.texCoord);
    float sigDist = median(msdf.r, msdf.g, msdf.b);
    
    float smoothing = 0.1;
    
    // Обводка (большая буква)
    float outlineDist = sigDist - 0.1;
    float outlineOpacity = clamp(outlineDist/smoothing + 0.5, 0.0, 1.0);
    
    // Основа
    float textDist = sigDist - 0.3;
    float textOpacity = clamp(textDist/smoothing + 0.5, 0.0, 1.0);
    
    // Комбинируем обводку и текст
    float3 outlineColor = float3(1.0, 1.0, 1.0); // Цвет обводки (например, чёрный)
    float3 textColor = float3(0.0, 0.0, 0.0); // Цвет текста (например, белый)
    float3 finalColor = mix(outlineColor, textColor, textOpacity);
    float finalOpacity = max(outlineOpacity, textOpacity);
    
    return float4(finalColor, finalOpacity);
}
