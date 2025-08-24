//
//  RoadLabel.metal
//  TucikMap
//
//  Created by Artem on 7/11/25.
//

#include <metal_stdlib>
using namespace metal;
#include "../Common.h"

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
    MeasuredText measuredText;
    float scale;
    int startPositionIndex;
    int endPositionIndex;
    float worldPathLen;
    bool isVertical;
    bool negativeDirection;
};

struct MapLabelIntersection {
    bool hide;
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
    bool show;
    float progress;
};

struct LocalPosition {
    float2 position;
};

float2 localTilePositionToScreenSpacePosition(float4x4 modelMatrix, float2 localPosition, Uniforms worldUniforms) {
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
                                    constant LocalPosition* localPositions [[buffer(6)]],
                                    constant LineToStartAt* lineToStartFrom [[buffer(7)]],
                                    constant StartRoadAt* startsFrom [[buffer(8)]],
                                    constant float& rotationYaw [[buffer(9)]],
                                    constant MapLabelIntersection* intersections [[buffer(10)]],
                                    constant float& animationDuration [[buffer(11)]],
                                    uint vertexID [[vertex_id]],
                                    uint instanceID [[instance_id]]
                                        ) {
    int symbolIndex = vertexID / 6;
    MapLabelSymbolMeta symbolMeta = symbolsMeta[symbolIndex];
    int lineIndex = symbolMeta.lineMetaIndex;
    
    LineToStartAt lineStartAtIndex = lineToStartFrom[lineIndex];
    int textsCount = lineStartAtIndex.count;
    int useInstance = min(int(instanceID), textsCount - 1);
    bool ignoreInstance = int(instanceID) >= textsCount;
    StartRoadAt startRoadAt = startsFrom[lineStartAtIndex.index + useInstance];
    
    MapLabelLineMeta lineMeta = linesMeta[lineIndex];
    MeasuredText measuredText = lineMeta.measuredText;
    float textWidth = measuredText.width; // размер текста в ширину
    float scale = lineMeta.scale;
    float worldPathLen = lineMeta.worldPathLen;
    float textScreenWidth = scale * textWidth;
    float glyphShift = symbolMeta.shiftX; // это сдвиг глифа в горизонтальном тексте
    
    int startLocalPositionIndex = lineMeta.startPositionIndex;
    int positionsSize = lineMeta.endPositionIndex - lineMeta.startPositionIndex; // сколько всего точек в массиве
    float textFactor = startRoadAt.startAt;
    
    bool isToTheRight = lineMeta.negativeDirection == false;
    if (lineMeta.isVertical == false) {
        bool inversionState = sin(rotationYaw) > 0;
        isToTheRight = isToTheRight ^ inversionState;
    } else {
        bool inversionState = cos(rotationYaw) < 0;
        isToTheRight = isToTheRight ^ inversionState;
    }
    int sign = isToTheRight ? 1 : -1;
    int addIndex = isToTheRight ? 0 : positionsSize - 1;
    
    float2 screenPoint = float2(0, 0);
    float textStartScreenShift = 0;
    float previousScreenLen = 0;
    float worldTextCenter = worldPathLen * textFactor;
    for (int i = 0; i < positionsSize - 1; i++) {
        float2 current = localPositions[startLocalPositionIndex + addIndex + sign * (i)].position;
        float2 next = localPositions[startLocalPositionIndex + addIndex + sign * (i + 1)].position;
        float len = length(next - current);
        
        float2 currentScreen = localTilePositionToScreenSpacePosition(modelMatrix, current, worldUniforms);
        float2 nextScreen = localTilePositionToScreenSpacePosition(modelMatrix, next, worldUniforms);
        float screenLen = length(nextScreen - currentScreen);
        
        if (worldTextCenter - len < 0 || i == positionsSize - 2) {
            float inSegmentWorldLen = worldTextCenter;
            float inSegmentWorldFactor = inSegmentWorldLen / len;
            float2 worldPoint = mix(current, next, inSegmentWorldFactor);
            screenPoint = localTilePositionToScreenSpacePosition(modelMatrix, worldPoint, worldUniforms);
            float inSegmentScreenLen = length(screenPoint - currentScreen);
            
            textStartScreenShift = previousScreenLen + inSegmentScreenLen - textScreenWidth / 2;
            break;
        }
        worldTextCenter -= len;
        previousScreenLen += screenLen;
    }
    
    
    // если центральная точка метки на дороге выходит за пределы экрана то игнорируем ее
    float2 viewportSize = worldUniforms.viewportSize;
    if (screenPoint.x + textScreenWidth < 0 ||
        screenPoint.y + textScreenWidth < 0 ||
        screenPoint.x - textScreenWidth > viewportSize.x ||
        screenPoint.y - textScreenWidth > viewportSize.y) {
        ignoreInstance = true;
    }
    
    textStartScreenShift += glyphShift * scale;
    
    // Мы нашли стартовую точку на длине экранной кривой и теперь рисуем текст
    int shiftIndex = 0;
    float2 screenCurrent = localTilePositionToScreenSpacePosition(modelMatrix,
                                                                  localPositions[startLocalPositionIndex + addIndex + sign * shiftIndex].position,
                                                                  worldUniforms);
    float2 screenNext = localTilePositionToScreenSpacePosition(modelMatrix,
                                                               localPositions[startLocalPositionIndex + addIndex + sign * (1 + shiftIndex)].position,
                                                               worldUniforms);
    
    
    float len = length(screenNext - screenCurrent);
    while (textStartScreenShift > len && positionsSize - 1 > shiftIndex) {
        textStartScreenShift -= len;
        shiftIndex += 1;
        screenCurrent = localTilePositionToScreenSpacePosition(modelMatrix,
                                                               localPositions[startLocalPositionIndex + addIndex + sign * shiftIndex].position,
                                                               worldUniforms
                                                               );
        screenNext = localTilePositionToScreenSpacePosition(modelMatrix,
                                                            localPositions[startLocalPositionIndex + addIndex + sign * (1 + shiftIndex)].position,
                                                            worldUniforms
                                                            );
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
    
    float2 vertexPos = screenCurrent + (rotatedGlyphPos * scale) + direction * textStartScreenShift;
    float4 position = float4(vertexPos, 0.0, 1.0);
    out.position = screenUniforms.projectionMatrix * screenUniforms.viewMatrix * position;
    out.texCoord = in.texCoord;
    out.ignore = ignoreInstance;
    
    MapLabelIntersection intersection = intersections[lineIndex];
    out.show = intersection.hide == false;
    out.progress = (worldUniforms.elapsedTimeSeconds - intersection.createdTime) / animationDuration;
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
    float textRange = 0.2;
    float outlineRange = 0.05;
    
    // Обводка
    float outlineDist = sigDist;  // Положительный сдвиг для внешнего контура (толщину регулируйте здесь)
    float outlineOpacity = smoothstep(outlineRange, outlineRange + 0.05, outlineDist);
    
    // Текст
    float textDist = sigDist;
    float textOpacity = smoothstep(textRange, textRange, textDist);
    
    // Комбинируем обводку и текст
    float3 outlineColor = float3(1.0, 1.0, 1.0); // Цвет обводки (например, чёрный)
    float3 textColor = float3(0.0, 0.0, 0.0); // Цвет текста (например, белый)
    float3 finalColor = mix(outlineColor, textColor, textOpacity);
    float finalOpacity = max(outlineOpacity, textOpacity);
    
    float show = mix(1 - in.progress, in.progress, in.show ? 1 : 0);
    return float4(finalColor, finalOpacity * show);
}
