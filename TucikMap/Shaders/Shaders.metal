//
//  Shaders.metal
//  TucikMap
//
//  Created by Artem on 5/27/25.
//

#include <metal_stdlib>
using namespace metal;

// Add necessary structures for transformation and rendering
struct Vertex {
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

// Updated vertex shader to include transformations
vertex Vertex vertex_main(uint vertexID [[vertex_id]],
                         constant float3 *positions [[buffer(0)]],
                         constant float4 *colors [[buffer(2)]],
                         constant Uniforms &uniforms [[buffer(1)]]
                         ) {
    
    float4 worldPosition = float4(positions[vertexID], 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    Vertex out;
    out.position = clipPosition;
    out.color = colors[vertexID];
    out.texCoord = float2(0.0, 0.0); // Default values
    return out;
}

fragment float4 fragment_main(Vertex in [[stage_in]]) {
    return in.color;
}

