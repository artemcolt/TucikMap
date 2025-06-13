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
    bool show;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
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
};

struct MapLabelIntersection {
    bool intersect;
};


vertex VertexOut labelsVertexShader(VertexIn in [[stage_in]],
                                    constant Uniforms &screenUniforms [[buffer(1)]],
                                    constant MapLabelSymbolMeta* symbolsMeta [[buffer(2)]],
                                    constant MapLabelLineMeta* linesMeta [[buffer(3)]],
                                    constant Uniforms &worldUniforms [[buffer(4)]],
                                    constant MapLabelIntersection* intersections [[buffer(5)]],
                                    uint vertexID [[vertex_id]]
                                    ) {
    int symbolIndex = vertexID / 6;
    MapLabelSymbolMeta symbolMeta = symbolsMeta[symbolIndex];
    int lineIndex = symbolMeta.lineMetaIndex;
    MapLabelLineMeta lineMeta = linesMeta[lineIndex];
    MeasuredText measuredText = lineMeta.measutedText;
    float textWidth = measuredText.width;
    float scale = lineMeta.scale;
    
    float4 worldLabelPos = float4(lineMeta.worldPosition, 0.0, 1.0);
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
    
    float2 textOffset = float2(textWidth / 2, 0);
    float4 position = translationMatrix * float4(in.position - textOffset, 0.0, 1.0);
    out.position = screenUniforms.projectionMatrix * screenUniforms.viewMatrix * position;
    out.texCoord = in.texCoord;
    out.show = intersections[lineIndex].intersect == false;
    return out;
}

fragment float4 labelsFragmentShader(VertexOut in [[stage_in]],
                                     texture2d<float> atlasTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]]) {
    // Чтение значения из MSDF атласа
    float4 msdf = atlasTexture.sample(textureSampler, in.texCoord);
    float sigDist = median(msdf.r, msdf.g, msdf.b) - 0.5;
    float opacity = clamp(sigDist/fwidth(sigDist) + 0.5, 0.0, 1.0);
    bool show = in.show;
    return float4(1.0, 0.0, 0.0, opacity * show);
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
