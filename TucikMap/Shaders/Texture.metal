//
//  Texture.metal
//  TucikMap
//
//  Created by Artem on 7/24/25.
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
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShaderTexture(Vertex vertexIn [[stage_in]],
                                     constant Uniforms& uniforms [[buffer(1)]]) {
    
    float4 worldPosition = float4(vertexIn.position, 0.0, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position = clipPosition;
    out.texCoord = vertexIn.texCoord;
    return out;
}

fragment float4 fragmentShaderTexture(VertexOut in [[stage_in]],
                                    texture2d<float> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = colorTexture.sample(textureSampler, in.texCoord);
    return color;
}
