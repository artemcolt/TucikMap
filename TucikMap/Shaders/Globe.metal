//
//  Globe.metal
//  TucikMap
//
//  Created by Artem on 7/23/25.
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

struct Vertex {
    float2 texCoord [[attribute(0)]];
    float yCoord  [[attribute(1)]];
    float xCoord  [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct GlobeParams {
    float globeRotation;
    float uShift;
    float globeRadius;
};

vertex VertexOut vertexShaderGlobe(Vertex vertexIn [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]],
                                   constant GlobeParams& globeParams [[buffer(2)]]) {
    
    constexpr float PI = M_PI_F;
    float theta = vertexIn.xCoord * PI + PI / 2.0;
    float y = vertexIn.yCoord * PI;
    float phi = 2.0 * atan(exp(y)) - PI / 2.0;

    float radius = globeParams.globeRadius;
    float4 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    spherePos.w = 1;
    
    float rotation          = globeParams.globeRotation;
    float4x4 translation    = translation_matrix(float3(0, 0, -radius));
    float4x4 globeRotation  = rotation_matrix(rotation, float3(1, 0, 0));
    float4 worldPosition    = translation * globeRotation * spherePos;
    
    float4 viewPosition     = uniforms.viewMatrix * worldPosition;
    float4 clipPosition     = uniforms.projectionMatrix * viewPosition;
    
    
    
    VertexOut out;
    out.position = clipPosition;
    out.texCoord = vertexIn.texCoord - float2(globeParams.uShift, 0);
    return out;
}

fragment float4 fragmentShaderGlobe(VertexOut in [[stage_in]],
                                    texture2d<float> colorTexture [[texture(0)]],
                                    sampler textureSampler[[sampler(0)]]) {
    float4 color = colorTexture.sample(textureSampler, in.texCoord);
    return color;
}
