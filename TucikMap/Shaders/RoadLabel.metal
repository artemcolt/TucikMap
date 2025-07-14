//
//  RoadLabel.metal
//  TucikMap
//
//  Created by Artem on 7/11/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct MapLabelSymbolMeta {
    int lineMetaIndex;
    float shiftX;
};

struct MeasuredText {
    float width;
    float top;
    float bottom;
};

struct MapLabelLineMeta {
    MeasuredText measutedText;
    float scale;
    int startPositionIndex;
    int endPositionIndex;
};

struct MapLabelIntersection {
    bool intersect;
    float createdTime;
};

struct StartRoadAt {
    float startAt;
};

struct LineToStartAt {
    int index;
    int count;
};

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    bool ignore;
    bool test;
};

float2 getScreenPosition(float4x4 modelMatrix, float2 localPosition, Uniforms worldUniforms) {
    float4 worldLabelPos = modelMatrix * float4(localPosition, 0.0, 1.0);
    float4 clipPos = worldUniforms.projectionMatrix * worldUniforms.viewMatrix * worldLabelPos;
    float3 ndc = float3(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
   
    float2 viewportSize = worldUniforms.viewportSize;
    float viewportWidth = viewportSize.x;
    float viewportHeight = viewportSize.y;
    float screenX = ((ndc.x + 1) / 2) * viewportWidth;
    float screenY = ((ndc.y + 1) / 2) * viewportHeight;
    float2 screenPos = float2(screenX, screenY);
    return screenPos;
}


vertex VertexOut roadLabelsVertexShader(VertexIn in [[stage_in]],
                                    constant Uniforms &screenUniforms [[buffer(1)]],
                                    constant MapLabelSymbolMeta* symbolsMeta [[buffer(2)]],
                                    constant MapLabelLineMeta* linesMeta [[buffer(3)]],
                                    constant Uniforms &worldUniforms [[buffer(4)]],
                                    constant float4x4& modelMatrix [[buffer(5)]],
                                    constant float2* positions [[buffer(6)]],
                                    constant LineToStartAt* lineToStartFrom [[buffer(7)]],
                                    constant StartRoadAt* startsFrom [[buffer(8)]],
                                    uint vertexID [[vertex_id]],
                                    uint instanceID [[instance_id]]
                                    ) {
    int symbolIndex = vertexID / 6;
    MapLabelSymbolMeta symbolMeta = symbolsMeta[symbolIndex];
    int lineIndex = symbolMeta.lineMetaIndex;
    MapLabelLineMeta lineMeta = linesMeta[lineIndex];
    MeasuredText measuredText = lineMeta.measutedText;
    float scale = lineMeta.scale;
    int positionsSize = lineMeta.endPositionIndex - lineMeta.startPositionIndex;
    
    
    // расчитываем длину всего пути
    float pathLen = 0;
    int shiftIndex2 = 0;
    while (positionsSize - 1 > shiftIndex2) {
        float2 screenCurrent2 = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + shiftIndex2], worldUniforms);
        float2 screenNext2 = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + 1 + shiftIndex2], worldUniforms);
        pathLen += length(screenNext2 - screenCurrent2);
        shiftIndex2 += 1;
    }
    
    float screenTextWidth = measuredText.width * scale;
    float halfScreenTextWidth = 0.5 * screenTextWidth;
    
    // First, compute the max fitCount based on non-overlapping hierarchical levels
    int fitCount = 0;
    if (pathLen >= screenTextWidth) {
        float ratio = pathLen / screenTextWidth;
        float logVal = log2(ratio);
        int maxLevel = max(0, int(floor(logVal)) - 1);  // Level k, starting from 0
        fitCount = (1 << (maxLevel + 1)) - 1;  // Total labels: 2^{maxLevel + 1} - 1
    }
    
    bool ignoreInstance = (int(instanceID) >= fitCount);  // Ignore extra instances
    
    // Now, for valid instances, compute the fractional position along the path
    float fraction = 0.5;  // Default for ID 0
    if (!ignoreInstance && instanceID > 0) {
        float iid = float(instanceID);
        float m = floor(log2(iid + 1.0)) + 1.0;  // "Denominator power" (m = level + 1)
        int mm = int(m);
        int cumPrev = (1 << (mm - 1)) - 1;
        int localId = int(iid) - cumPrev;
        float num = float(2 * localId + 1);
        float den = pow(2.0, m);  // 2^m
        fraction = num / den;
    }
    
//    int fitCount = int(pathLen / screenTextWidth);
//    bool ignoreInstance = instanceID >= uint(fitCount);
    float shiftX = symbolMeta.shiftX * scale + 0.5 * pathLen - halfScreenTextWidth;
    
    int shiftIndex = 0;
    float2 screenCurrent = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + shiftIndex], worldUniforms);
    float2 screenNext = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + 1 + shiftIndex], worldUniforms);
    float len = length(screenNext - screenCurrent);
    
    while (shiftX > len && positionsSize - 1 > shiftIndex) {
        shiftX -= len;
        shiftIndex += 1;
        screenCurrent = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + shiftIndex], worldUniforms);
        screenNext = getScreenPosition(modelMatrix, positions[lineMeta.startPositionIndex + 1 + shiftIndex], worldUniforms);
        len = length(screenNext - screenCurrent);
    }
    
    
    VertexOut out;
    float2 direction = normalize(screenNext - screenCurrent);
    float tangentAngle = -atan2(direction.y, direction.x);
    
    float cosTheta = cos(tangentAngle);
    float sinTheta = sin(tangentAngle);
    float2x2 rotationMatrix = float2x2(
        cosTheta, -sinTheta,
        sinTheta, cosTheta
    );
    
    float textHeight = abs(measuredText.top - measuredText.bottom);
    float2 glyphPosition = in.position - float2(0, textHeight / 3);
    float2 rotatedGlyphPos = rotationMatrix * glyphPosition;
    
    float2 vertexPos = screenCurrent + (rotatedGlyphPos * scale) + direction * shiftX;
    float4 position = float4(vertexPos, 0.0, 1.0);
    out.position = screenUniforms.projectionMatrix * screenUniforms.viewMatrix * position;
    out.texCoord = in.texCoord;
    out.ignore = ignoreInstance;
    out.test = positionsSize == 5;
    return out;
}

fragment float4 roadLabelsFragmentShader(VertexOut in [[stage_in]],
                                     texture2d<float> atlasTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]]) {
    if (in.ignore) {
        discard_fragment();
    }

    
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
    
//    if (in.test) {
//        finalColor = float3(0, 1.0, 0);
//    }
    
    return float4(finalColor, finalOpacity);
}
