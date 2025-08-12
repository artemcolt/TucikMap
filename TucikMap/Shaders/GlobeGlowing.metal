//
//  GlobeGlowing.metal
//  TucikMap
//
//  Created by Artem on 8/10/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct VertexIn {
    float3 position;
};

struct MapParams {
    float factor;
    float globeRadius;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct VertexOut {
    float4 clip [[position]];
};

vertex VertexOut globeGlowingVertex(uint vertexID [[vertex_id]],
                                    constant VertexIn* vertices [[buffer(0)]],
                                    constant Uniforms& uniforms [[buffer(1)]],
                                    constant MapParams& mapParams [[buffer(2)]]) {
    float size = 0.35;
    float globeRadius = mapParams.globeRadius;
    float4x4 transition = translation_matrix(float3(0, 0, -globeRadius));
    
    VertexIn vertexIn = vertices[vertexID];
    float4 worldPosition = transition * float4(vertexIn.position * size, 1);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.clip = clipPosition;
    return out;
}

fragment float4 globeGlowingFragment(VertexOut in [[stage_in]]) {
    return float4(1, 0, 0, 1);
}
