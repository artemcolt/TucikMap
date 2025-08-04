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
    float transition;
};

float latToMercatorY(float latitudeRadians) {
    float sin_phi = sin(latitudeRadians);
    // Обработка крайних случаев: если |sin_phi| близко к 1, ограничить, чтобы избежать NaN/inf
    sin_phi = clamp(sin_phi, -0.999999f, 0.999999f);
    float log_term = log((1.0f + sin_phi) / (1.0f - sin_phi));
    float y_proj = 0.5f * log_term;
    float y_norm = y_proj / M_PI_F;
    return y_norm;
}

vertex VertexOut vertexShaderGlobe(Vertex vertexIn [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]],
                                   constant GlobeParams& globeParams [[buffer(2)]]) {
    
    constexpr float PI = M_PI_F;
    constexpr float HALF_PI = M_PI_F / 2.0;
    float theta = vertexIn.xCoord * PI + HALF_PI;
    float y = vertexIn.yCoord * PI;
    float phi = 2.0 * atan(exp(y)) - HALF_PI;

    float radius = globeParams.globeRadius;
    float4 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    spherePos.w = 1;
    
    float perimeter           = 2.0 * PI * radius;
    float halfPerimeter       = perimeter / 2.0;
    
    float rotation            = globeParams.globeRotation;
    float4x4 translation      = translation_matrix(float3(0, 0, -radius));
    float4x4 globeRotation    = rotation_matrix(rotation, float3(1, 0, 0));
    float4 globeWorldPosition = translation * globeRotation * spherePos;
    
    float distortion          = cos(rotation);
    float planeShiftY         = -latToMercatorY(rotation);
    
    float planeFactor = distortion * halfPerimeter;
    float4 planeWorldPosition = float4(-vertexIn.xCoord * planeFactor, vertexIn.yCoord * planeFactor + planeShiftY * planeFactor, 0, 1);
    

    float transition          = (cos(uniforms.elapsedTimeSeconds * 0.5) + 1) / 2;
    transition                = globeParams.transition;
    
    //transition = 1;
    float4 worldPosition      = mix(globeWorldPosition, planeWorldPosition, transition);
    float4 viewPosition       = uniforms.viewMatrix * worldPosition;
    float4 clipPosition       = uniforms.projectionMatrix * viewPosition;
    
    
    
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

