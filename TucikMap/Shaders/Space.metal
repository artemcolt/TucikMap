//
//  Space.metal
//  TucikMap
//
//  Created by Artem on 8/10/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct Vertex {
    float4 position [[position]];
    float pointSize [[point_size]];
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

vertex Vertex starVertex(uint vertexID [[vertex_id]],
                         constant Vertex* vertices [[buffer(0)]],
                         constant Uniforms& uniforms [[buffer(1)]],
                         constant GlobeShadersParams& mapParams [[buffer(2)]]) {
    
    float factor = mapParams.scale;
    float4x4 scale = scale_matrix(float3(factor));
    float4x4 latitudeRotation = rotation_matrix(mapParams.latitude, float3(1, 0, 0));
    float4x4 longitudeRotation = rotation_matrix(-mapParams.longitude, float3(0, 1, 0));
    float4x4 fullRotation = latitudeRotation * longitudeRotation;
    
    Vertex vert = vertices[vertexID];
    float4 worldPosition = fullRotation * scale * vert.position;
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    vert.position = clipPosition;
    
    return vert;
}

fragment float4 starFragment(Vertex in [[stage_in]],
                             float2 pointCoord [[point_coord]]) {
    float dist = length(pointCoord - float2(0.5));
    float alpha = 1.0 - smoothstep(0, 0.45, dist);
    
    // Возвращаем цвет с модифицированной альфой
    return float4(in.color.rgb, alpha);
}
