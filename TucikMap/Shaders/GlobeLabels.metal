//
//  GlobeLabels.metal
//  TucikMap
//
//  Created by Artem on 8/6/25.
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
    float2 localPosition;
};

struct MapLabelIntersection {
    bool intersect;
    float createdTime;
};

struct GlobeLabelsParams {
    float latitude;
    float longitude;
    float globeRadius;
    float centerX;
    float centerY;
    float factor;
};


vertex VertexOut globeLabelsVertexShader(VertexIn in [[stage_in]],
                                         constant Uniforms &screenUniforms [[buffer(1)]],
                                         constant MapLabelSymbolMeta* symbolsMeta [[buffer(2)]],
                                         constant MapLabelLineMeta* linesMeta [[buffer(3)]],
                                         constant Uniforms &worldUniforms [[buffer(4)]],
                                         constant MapLabelIntersection* intersections [[buffer(5)]],
                                         constant float& animationDuration [[buffer(6)]],
                                         constant GlobeLabelsParams& globeLabelsParams [[buffer(7)]],
                                         uint vertexID [[vertex_id]]
                                         ) {
    int symbolIndex = vertexID / 6;
    MapLabelSymbolMeta symbolMeta = symbolsMeta[symbolIndex];
    int lineIndex = symbolMeta.lineMetaIndex;
    MapLabelLineMeta lineMeta = linesMeta[lineIndex];
    MeasuredText measuredText = lineMeta.measutedText;
    float textWidth = measuredText.width;
    float scale = lineMeta.scale;
    
    // Локальное преобразование
    float4x4 localScale = scale_matrix(float3(globeLabelsParams.factor, globeLabelsParams.factor, 1.0));
    float4x4 localTranslation = translation_matrix(float3(globeLabelsParams.centerX, globeLabelsParams.centerY, 0));
    
    // Начальный преобразоватор в коориднаты глобуса
    float4 labelCoord4 = localTranslation * localScale * float4(lineMeta.localPosition, 0, 1);
    float2 labelCoord = labelCoord4.xy;
    
    constexpr float PI = M_PI_F;
    constexpr float HALF_PI = M_PI_F / 2.0;
    float theta = -labelCoord.x * PI + HALF_PI;
    float y = labelCoord.y * PI;
    float phi = 2.0 * atan(exp(y)) - HALF_PI;

    float radius = globeLabelsParams.globeRadius;
    float4 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    spherePos.w = 1;
    
    
    float4x4 globeTranslate = translation_matrix(float3(0, 0, -radius));
    float4x4 globeLongitude = rotation_matrix(-globeLabelsParams.longitude, float3(0, 1, 0));
    float4x4 globeLatitude = rotation_matrix(globeLabelsParams.latitude, float3(1, 0, 0));
    float4x4 globeRotation = globeLatitude * globeLongitude;
    
    float4 worldLabelPos = globeTranslate * globeRotation * spherePos;
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

fragment float4 globeLabelsFragmentShader(VertexOut in [[stage_in]],
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
    
    float show = mix(1 - in.progress, in.progress, in.show ? 1 : 0);
    return float4(finalColor, finalOpacity * show);
}
