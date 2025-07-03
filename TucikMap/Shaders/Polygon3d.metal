//
//  Polygon3d.metal
//  TucikMap
//
//  Created by Artem on 7/2/25.
//

#include <metal_stdlib>
using namespace metal;

// Add necessary structures for transformation and rendering
struct VertexIn {
    float3 position [[attribute(0)]];
    unsigned char styleIndex [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoord;    // Texture coordinates for future use
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct Style {
    float4 color;
};


struct TileUniform {
    int tileX;
    int tileY;
    int tileZ;
};

struct AllTilesUniform {
    float mapSize;
    float panX;
    float panY;
};


vertex VertexOut draw_3Dpolygon_vertex(VertexIn vertexIn [[stage_in]],
                                  constant Uniforms &uniforms [[buffer(1)]],
                                  constant Style* styles [[buffer(2)]],
                                  constant float4x4 &modelMatrix [[buffer(3)]]
                                  ) {
    
    float3 position = vertexIn.position;
    float4 worldPosition = modelMatrix * float4(position, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position = clipPosition;
    out.color = styles[vertexIn.styleIndex].color;
    return out;
}

fragment float4 draw_3Dpolygon_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}
