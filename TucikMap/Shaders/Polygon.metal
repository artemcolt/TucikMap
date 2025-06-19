//
//  Polygon.metal
//  TucikMap
//
//  Created by Artem on 6/5/25.
//

#include <metal_stdlib>
using namespace metal;

// Add necessary structures for transformation and rendering
struct VertexIn {
    float2 position [[attribute(0)]];
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


vertex VertexOut draw_polygon_vertex(VertexIn vertexIn [[stage_in]],
                                  constant Uniforms &uniforms [[buffer(1)]],
                                  constant Style* styles [[buffer(2)]],
                                  constant TileUniform &tileUniform [[buffer(3)]],
                                  constant AllTilesUniform &allTilesUniform [[buffer(4)]]
                                  ) {
    float mapSize = allTilesUniform.mapSize;
    float zoomFactor = pow(2.0, tileUniform.tileZ);
    
    float tileCenterX = tileUniform.tileX + 0.5;
    float tileCenterY = tileUniform.tileY + 0.5;
    float tileSize = mapSize / zoomFactor;
    
    float tileWorldX = tileCenterX * tileSize - mapSize / 2;
    float tileWorldY = mapSize / 2 - tileCenterY * tileSize;
    
    float panX = allTilesUniform.panX;
    float panY = allTilesUniform.panY;
    
    float scaleX = tileSize / 2;
    float scaleY = tileSize / 2;
    float offsetX = tileWorldX + panX;
    float offsetY = tileWorldY + panY;
    
    float4x4 modelMatrix = {
        float4(scaleX, 0.0,    0.0,    0.0),
        float4(0.0,    scaleY, 0.0,    0.0),
        float4(0.0,    0.0,    1.0,    0.0),
        float4(offsetX,    offsetY,    0.0,    1.0)
    };
    
    float2 position = vertexIn.position;
    float4 worldPosition = modelMatrix * float4(position, 0.0, 1.0);
    float4 viewPosition = uniforms.viewMatrix * worldPosition;
    float4 clipPosition = uniforms.projectionMatrix * viewPosition;
    
    VertexOut out;
    out.position = clipPosition;
    out.color = styles[vertexIn.styleIndex].color;
    return out;
}

fragment float4 draw_polygon_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}
