//
//  GlobeMarkers.metal
//  TucikMap
//
//  Created by Artem on 8/22/25.
//

#include <metal_stdlib>
using namespace metal;
#include "../Common.h"

struct VertexIn {
    float2 texCoord [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float progress;
    bool show;
};

struct Uniforms {
    metal::float4x4 projectionMatrix;
    metal::float4x4 viewMatrix;
    float2 viewportSize;
    float elapsedTimeSeconds;
};

struct MapMarkerMeta {
    float size;
    float2 globeNormalizedPosition;
};

// на всю карту общие парметры
struct GlobeParams {
    float latitude;
    float longitude;
    float globeRadius;
};


vertex VertexOut globeMarkersVertexShader(VertexIn in [[stage_in]],
                                          constant Uniforms &screenUniforms [[buffer(1)]],
                                          constant MapMarkerMeta* markersMeta [[buffer(2)]],
                                          constant Uniforms &worldUniforms [[buffer(3)]],
                                          constant GlobeParams& globeParams [[buffer(4)]],
                                          uint vertexID [[vertex_id]]) {
    int markerIndex = vertexID / 6;
    
    MapMarkerMeta markerMeta = markersMeta[markerIndex];
    float2 markerCoord = markerMeta.globeNormalizedPosition;
    float radius = globeParams.globeRadius;
    float longitude = globeParams.longitude;
    float latitude = globeParams.latitude;
    
    float4 globeWorldLabelPos = getGlobeWorldPosition(markerCoord, radius, longitude, latitude);
    float4 worldPosition = globeWorldLabelPos;
    
    
    float4 clipPos = worldUniforms.projectionMatrix * worldUniforms.viewMatrix * worldPosition;
    float3 ndc = float3(clipPos.x / clipPos.w, clipPos.y / clipPos.w, clipPos.z / clipPos.w);
   
    float2 viewportSize = worldUniforms.viewportSize;
    float viewportWidth = viewportSize.x;
    float viewportHeight = viewportSize.y;
    float screenX = ((ndc.x + 1) / 2) * viewportWidth;
    float screenY = ((ndc.y + 1) / 2) * viewportHeight;
    
    float markerSize = markerMeta.size;
    int vertexIndex = vertexID % 6;
    float2 offsets[6] = {
        float2(0.0, 0.0), // left-bottom
        float2(1.0, 0.0), // right-bottom
        float2(1.0, 1.0), // right-top
        float2(0.0, 0.0), // left-bottom
        float2(1.0, 1.0), // right-top
        float2(0.0, 1.0)  // left-top
    };
    float2 screenPos = float2(screenX, screenY) + offsets[vertexIndex] * markerSize - float2(markerSize / 2.0);
    screenPos = floor(screenPos);
    
    VertexOut out;
    out.position = screenUniforms.projectionMatrix * screenUniforms.viewMatrix * float4(screenPos, 0, 1);
    out.texCoord = in.texCoord;
    out.show = true;
    out.progress = 1.0;
    return out;
}

fragment float4 globeMarkersFragmentShader(VertexOut in [[stage_in]],
                                          texture2d<float> atlasTexture [[texture(0)]],
                                          sampler textureSampler [[sampler(0)]]) {
    float2 texCoord = in.texCoord;
    texCoord.y = 1.0 - texCoord.y;
    
    float4 markerTexture = atlasTexture.sample(textureSampler, texCoord);
    
    return markerTexture;
}
