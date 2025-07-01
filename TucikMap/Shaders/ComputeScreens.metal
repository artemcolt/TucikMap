//
//  ComputeScreens.metal
//  TucikMap
//
//  Created by Artem on 6/23/25.
//

#include <metal_stdlib>
using namespace metal;

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
