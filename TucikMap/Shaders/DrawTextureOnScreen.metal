//
//  PostProcessing.metal
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut drawTextureOnScreenVertex(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 drawTextureOnScreenFragment(VertexOut in [[stage_in]],
                                            texture2d<float> sourceTexture [[texture(0)]]) {
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    return sourceTexture.sample(samplr, in.texCoord);
}
