//
//  ComputeScreens.metal
//  TucikMap
//
//  Created by Artem on 6/23/25.
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

struct InputComputeScreenVertex {
    float2 location;
    short matrixId;
};

kernel void computeScreens(
    device const InputComputeScreenVertex* vertices [[buffer(0)]],
    device float2* output [[buffer(1)]],
    constant Uniforms& uniforms [[buffer(2)]],
    constant float4x4* modelMatrices [[buffer(3)]],
    uint gid [[thread_position_in_grid]]
) {
    InputComputeScreenVertex inputVertex = vertices[gid];
    float4 worldLabelPos = modelMatrices[inputVertex.matrixId] * float4(inputVertex.location, 0.0, 1.0);
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

// на всю карту общие парметры
struct GlobeParams {
    float latitude;
    float longitude;
    float globeRadius;
};

// это данные для одного тайла
struct GlobeLabelsParams {
    float centerX;
    float centerY;
    float factor;
};

kernel void computeScreensGlobe(
    device const InputComputeScreenVertex* vertices [[buffer(0)]],
    device float2* output [[buffer(1)]],
    constant Uniforms& uniforms [[buffer(2)]],
    constant GlobeLabelsParams* globeLabelsParamsArray [[buffer(3)]],
    constant GlobeParams& globeParams [[buffer(4)]],
    uint gid [[thread_position_in_grid]]
) {
    InputComputeScreenVertex inputVertex = vertices[gid];
    float2 inputLoc = inputVertex.location;
    GlobeLabelsParams globeLabelsParams = globeLabelsParamsArray[inputVertex.matrixId];
    
    // Локальное преобразование
    float4x4 localScale = scale_matrix(float3(globeLabelsParams.factor, globeLabelsParams.factor, 1.0));
    float4x4 localTranslation = translation_matrix(float3(globeLabelsParams.centerX, globeLabelsParams.centerY, 0));
    
    // Начальный преобразоватор в коориднаты глобуса
    float4 labelCoord4 = localTranslation * localScale * float4(inputLoc, 0, 1);
    float2 labelCoord = labelCoord4.xy;
    
    
    constexpr float PI = M_PI_F;
    constexpr float HALF_PI = M_PI_F / 2.0;
    float theta = -labelCoord.x * PI + HALF_PI;
    float y = labelCoord.y * PI;
    float phi = 2.0 * atan(exp(y)) - HALF_PI;

    float radius = globeParams.globeRadius;
    float4 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    spherePos.w = 1;
    
    float4x4 globeTranslate = translation_matrix(float3(0, 0, -radius));
    float4x4 globeLongitude = rotation_matrix(-globeParams.longitude, float3(0, 1, 0));
    float4x4 globeLatitude = rotation_matrix(globeParams.latitude, float3(1, 0, 0));
    float4x4 globeRotation = globeLatitude * globeLongitude;
    float4 worldLabelPos = globeTranslate * globeRotation * spherePos;
    
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
