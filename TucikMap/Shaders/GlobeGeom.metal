//
//  GlobeGeom.metal
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct MapParams {
    float globeRadius;
    float factor;
    float latitude;
};

vertex VertexOut globeGeomVertex(VertexIn vertexIn [[stage_in]],
                                 constant Uniforms &uniforms [[buffer(1)]],
                                 constant MapParams& mapParams [[buffer(2)]]) {
    
    float border = 0.1;
    float4x4 rotation = rotation_matrix(mapParams.latitude, float3(1, 0, 0));
    float4x4 translation = translation_matrix(float3(0, 0, -mapParams.globeRadius));
    float4x4 scale = scale_matrix(float3(mapParams.factor + border));
    
    float4 worldPosition = translation * rotation * scale * float4(vertexIn.position, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position = clipPosition;
    return out;
}

fragment float4 globeGeomFragment(VertexOut in [[stage_in]]) {
    return float4(1, 1, 1, 1);
}
