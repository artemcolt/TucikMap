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
    bool clipTexture;
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

vertex VertexOut vertexShaderGlobe(Vertex vertexIn [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]],
                                   constant GlobeShadersParams& globeShadersParams [[buffer(2)]]) {
    float2 sphereGenCoord = float2(vertexIn.xCoord, vertexIn.yCoord);
    
    float PI = M_PI_F;
    float radius = globeShadersParams.globeRadius;
    float4 spherePos = float4(getSpherePos(sphereGenCoord, radius), 1.0);
    
    float rotation            = globeShadersParams.latitude;
    float4x4 translation      = translation_matrix(float3(0, 0, -radius));
    float4x4 globeRotation    = rotation_matrix(rotation, float3(1, 0, 0));
    float4 globeWorldPosition = translation * globeRotation * spherePos;
    
    // plane position
    float distortion          = cos(rotation);
    float planeShiftY         = -latToMercatorY(rotation);
    float perimeter           = 2.0 * PI * radius;
    float halfPerimeter       = perimeter / 2.0;
    float planeFactor         = distortion * halfPerimeter;
    float4 planeWorldPosition = float4(vertexIn.xCoord * planeFactor, vertexIn.yCoord * planeFactor + planeShiftY * planeFactor, 0, 1);
    

    float transition          = globeShadersParams.transition;
    
    float4 worldPosition      = mix(globeWorldPosition, planeWorldPosition, transition);
    float4 viewPosition       = uniforms.viewMatrix * worldPosition;
    float4 clipPosition       = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position        = clipPosition;
    
    float startTexU     = globeShadersParams.startAndEndUV[0];
    float endTexU       = globeShadersParams.startAndEndUV[1];
    float startTexV     = globeShadersParams.startAndEndUV[2];
    float endTexV       = globeShadersParams.startAndEndUV[3];
    
    
    float2 tex          = vertexIn.texCoord - float2(globeShadersParams.uShift, 0);
    out.clipTexture     = globeShadersParams.scale > 8;
    
    tex.x               = (tex.x - startTexU) / (endTexU - startTexU);
    tex.y               = (tex.y - startTexV) / (endTexV - startTexV);
    
    out.texCoord        = tex;
    
    return out;
}

struct FragmentOut {
    float4 color0 [[color(0)]];  // Основная сцена
};

fragment FragmentOut fragmentShaderGlobe(VertexOut in [[stage_in]],
                                         texture2d<float> colorTexture [[texture(0)]],
                                         sampler textureSampler[[sampler(0)]]) {
    float2 mTexCrd = in.texCoord;
    float4 visibleZoneColor = colorTexture.sample(textureSampler, mTexCrd);
    float4 useColor = visibleZoneColor;
    FragmentOut out;
    out.color0 = useColor;
    
    if ((mTexCrd.x < 0 || mTexCrd.x > 1 || mTexCrd.y < 0 || mTexCrd.y > 1) && in.clipTexture) {
        out.color0 = float4(1);
    }
    
    return out;
}

