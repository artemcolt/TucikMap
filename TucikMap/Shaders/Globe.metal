//
//  Globe.metal
//  TucikMap
//
//  Created by Artem on 7/23/25.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct Vertex {
    float2 texCoord [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShaderGlobe(Vertex vertexIn [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]]) {
    float2 tex = vertexIn.texCoord;
    float lon = 2.0 * M_PI_F * (tex.x - 0.5);
    float merc_y = M_PI_F * (1.0 - 2.0 * tex.y);
    float lat = 2.0 * atan(exp(merc_y)) - M_PI_F / 2.0;
    
    float radius = 1.0;
    float clat = cos(lat);
    float slat = sin(lat);
    float clon = cos(lon);
    float slon = sin(lon);
    
    float3 spherePos = float3(clat * clon, clat * slon, slat) * radius;
    float4 worldPosition = float4(spherePos, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position = clipPosition;
    out.texCoord = vertexIn.texCoord;
    return out;
}

fragment float4 fragmentShaderGlobe(VertexOut in [[stage_in]],
                                    texture2d<float> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = colorTexture.sample(textureSampler, in.texCoord);
    return color;
}
