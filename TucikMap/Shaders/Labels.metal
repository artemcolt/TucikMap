//
//  Labels.metal
//  TucikMap
//
//  Created by Artem on 6/9/25.
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
    float progress;
    bool show;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct MapLabelSymbolMeta {
    int lineMetaIndex;
};

struct MeasuredText {
    float width;
    float top;
    float bottom;
};

struct MapLabelLineMeta {
    MeasuredText measutedText;
    float scale;
    float2 worldPosition;
    int tileIndex;
};

struct MapLabelIntersection {
    bool intersect;
    float createdTime;
};


vertex VertexOut labelsVertexShader(VertexIn in [[stage_in]],
                                    constant Uniforms &screenUniforms [[buffer(1)]],
                                    constant MapLabelSymbolMeta* symbolsMeta [[buffer(2)]],
                                    constant MapLabelLineMeta* linesMeta [[buffer(3)]],
                                    constant Uniforms &worldUniforms [[buffer(4)]],
                                    constant MapLabelIntersection* intersections [[buffer(5)]],
                                    constant float& animationDuration [[buffer(6)]],
                                    constant float4x4* matrixModels [[buffer(7)]],
                                    uint vertexID [[vertex_id]]
                                    ) {
    int symbolIndex = vertexID / 6;
    MapLabelSymbolMeta symbolMeta = symbolsMeta[symbolIndex];
    int lineIndex = symbolMeta.lineMetaIndex;
    MapLabelLineMeta lineMeta = linesMeta[lineIndex];
    MeasuredText measuredText = lineMeta.measutedText;
    float textWidth = measuredText.width;
    float scale = lineMeta.scale;
    
    float4 worldLabelPos = matrixModels[lineMeta.tileIndex] * float4(lineMeta.worldPosition, 0.0, 1.0);
    float4 clipPos = worldUniforms.projectionMatrix * worldUniforms.viewMatrix * worldLabelPos;
    float3 ndc = float3(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
   
    float2 viewportSize = worldUniforms.viewportSize;
    float viewportWidth = viewportSize.x;
    float viewportHeight = viewportSize.y;
    float screenX = ((ndc.x + 1) / 2) * viewportWidth;
    float screenY = ((ndc.y + 1) / 2) * viewportHeight;
    float2 screenPos = float2(screenX, screenY);
    
    VertexOut out;
    float3 t = float3(screenPos.x, screenPos.y, 0);
    float4x4 translationMatrix = float4x4(scale, 0.0, 0.0, 0.0,
                                          0.0, scale, 0.0, 0.0,
                                          0.0, 0.0, 1.0, 0.0,
                                          t.x, t.y, t.z, 1.0);
    
    MapLabelIntersection intersection = intersections[lineIndex];
    
    float2 vertexPos = in.position;
    float2 textOffset = float2(textWidth / 2, 0);
    float4 position = translationMatrix * float4(vertexPos - textOffset, 0.0, 1.0);
    out.position = screenUniforms.projectionMatrix * screenUniforms.viewMatrix * position;
    out.texCoord = in.texCoord;
    out.show = intersection.intersect == false;
    out.progress = (worldUniforms.elapsedTimeSeconds - intersection.createdTime) / animationDuration;
    return out;
}

fragment float4 labelsFragmentShader(VertexOut in [[stage_in]],
                                     texture2d<float> atlasTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]]) {
    // Чтение значения из MSDF атласа
    float4 msdf = atlasTexture.sample(textureSampler, in.texCoord);
    float sigDist = median(msdf.r, msdf.g, msdf.b);
    
    // Обводка (большая буква)
    float outlineDist = sigDist - 0;
    float outlineOpacity = clamp(outlineDist/fwidth(outlineDist) + 0.5, 0.0, 1.0);
    
    // Основа
    float textDist = sigDist - 0.1;
    float textOpacity = clamp(textDist/fwidth(textDist) + 0.5, 0.0, 1.0);
    
    // Комбинируем обводку и текст
    float3 outlineColor = float3(1.0, 1.0, 1.0); // Цвет обводки (например, чёрный)
    float3 textColor = float3(0.0, 0.0, 0.0); // Цвет текста (например, белый)
    float3 finalColor = mix(outlineColor, textColor, textOpacity);
    float finalOpacity = max(outlineOpacity, textOpacity);
    
    float show = mix(1 - in.progress, in.progress, in.show ? 1 : 0);
    return float4(finalColor, finalOpacity * show);
}

kernel void transformKernel(
                            device const float2* vertices [[buffer(0)]],
                            device float2* output [[buffer(1)]],
                            constant Uniforms& uniforms [[buffer(2)]],
                            uint gid [[thread_position_in_grid]]
                            ) {
    float2 worldLabelPosition = vertices[gid];
    float4 worldLabelPos = float4(worldLabelPosition, 0.0, 1.0);
    float4 clipPos = uniforms.projectionMatrix * uniforms.viewMatrix * worldLabelPos;
    float3 ndc = float3(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
    float2 viewportSize = uniforms.viewportSize;
    float viewportWidth = viewportSize.x;
    float viewportHeight = viewportSize.y;
    float screenX = ((ndc.x + 1) / 2) * viewportWidth;
    float screenY = ((ndc.y + 1) / 2) * viewportHeight;
    float2 screenPos = float2(screenX, screenY);
    output[gid] = screenPos;
}
