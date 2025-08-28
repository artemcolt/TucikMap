//
//  GlobeCaps.metal
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

// Add necessary structures for transformation and rendering
struct Vertex {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct GlobeShadersParams {
    float latitude;
    float longitude;
    float scale;
    float uShift;
    float globeRadius;
    float transition;
    float4 startAndEndUV;
    float3 planeNormal;
};

vertex Vertex globeCapsVertex(uint vertexID [[vertex_id]],
                              constant float3 *positions [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]],
                              constant GlobeShadersParams &globeShadersParams [[buffer(2)]],
                              constant float4 *colors [[buffer(3)]]
                              ) {
    
    float4x4 scale = scale_matrix(float3(globeShadersParams.scale));
    float4x4 rotateLatitude = rotation_matrix(globeShadersParams.latitude, float3(1, 0, 0));
    float4x4 translation = translation_matrix(float3(0, 0, -globeShadersParams.globeRadius));
    float4 worldPosition = translation * rotateLatitude * scale * float4(positions[vertexID], 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    float fade = 1.0;
    Vertex out;
    out.position = clipPosition;
    float4 color = colors[vertexID];
    out.color = float4(color.xyz, color.w * fade);
    return out;
}

struct FragmentOut {
    float4 color0 [[color(0)]];  // Основная сцена
};


fragment FragmentOut globeCapsFragment(Vertex in [[stage_in]]) {
    FragmentOut out;
    out.color0 = in.color;
    return out;
}

