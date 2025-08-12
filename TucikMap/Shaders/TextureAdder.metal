//
//  TextureAdder.metal
//  TucikMap
//
//  Created by Artem on 8/11/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void add_textures(texture2d<float, access::read> sceneTex [[texture(0)]],
                         texture2d<float, access::read> bluredTex [[texture(1)]],
                         texture2d<float, access::read> maskedTex [[texture(2)]],
                         texture2d<float, access::write> outTex [[texture(3)]],
                         uint2 gid [[thread_position_in_grid]]) {
    float intensity = 2.0;
    
    float4 bluredColor = float4(bluredTex.read(gid).r * intensity);
    float4 maskedColor = float4(maskedTex.read(gid).r);
    float4 sceneColor = sceneTex.read(gid);
    
    float4 outColor = mix(bluredColor + sceneColor, sceneColor, maskedColor.r);
    
    outTex.write(outColor, gid);
}
