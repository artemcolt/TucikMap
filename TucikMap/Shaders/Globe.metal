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
    float2 position [[attribute(0)]];
    float2 planeCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct GlobeParams {
    float globeRotation;
    float uShift;
};

// Функция для создания матрицы трансляции
float4x4 translation_matrix(float3 translation) {
    return float4x4(
        float4(1.0f, 0.0f, 0.0f, 0.0f),
        float4(0.0f, 1.0f, 0.0f, 0.0f),
        float4(0.0f, 0.0f, 1.0f, 0.0f),
        float4(translation.x, translation.y, translation.z, 1.0f)
    );
}

// Функция для создания матрицы вращения вокруг произвольной оси
float4x4 rotation_matrix(float angle, float3 axis) {
    // Нормализуем ось
    axis = normalize(axis);
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;
    
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    float one_minus_cos = 1.0f - cos_angle;
    
    // Компоненты матрицы вращения (формула Родригеса)
    float xx = x * x * one_minus_cos + cos_angle;
    float xy = x * y * one_minus_cos - z * sin_angle;
    float xz = x * z * one_minus_cos + y * sin_angle;
    
    float yx = y * x * one_minus_cos + z * sin_angle;
    float yy = y * y * one_minus_cos + cos_angle;
    float yz = y * z * one_minus_cos - x * sin_angle;
    
    float zx = z * x * one_minus_cos - y * sin_angle;
    float zy = z * y * one_minus_cos + x * sin_angle;
    float zz = z * z * one_minus_cos + cos_angle;
    
    // Сборка матрицы 4x4
    return float4x4(
        float4(xx, yx, zx, 0.0f),
        float4(xy, yy, zy, 0.0f),
        float4(xz, yz, zz, 0.0f),
        float4(0.0f, 0.0f, 0.0f, 1.0f)
    );
}

vertex VertexOut vertexShaderGlobe(Vertex vertexIn [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]],
                                   constant GlobeParams& globeParams [[buffer(2)]]) {
    float2 planeCoord = vertexIn.planeCoord;

    constexpr float PI = M_PI_F;
    float theta = planeCoord.x * 2.0 * PI - PI / 2.0;
    float y = (2.0 * planeCoord.y - 1.0) * PI;
    float phi = 2.0 * atan(exp(y)) - PI / 2.0;

    float radius = 0.2;
    float4 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    spherePos.w = 1;
    
    float rotation          = globeParams.globeRotation;
    float4x4 translation    = translation_matrix(float3(0, 0, -radius));
    float4x4 globeRotation  = rotation_matrix(rotation, float3(1, 0, 0));
    float4 worldPosition    = translation * globeRotation * spherePos;
    
    float4 viewPosition     = uniforms.viewMatrix * worldPosition;
    float4 clipPosition     = uniforms.projectionMatrix * viewPosition;
    
    float2 texCoord         = float2(1, 1) - vertexIn.planeCoord - float2(globeParams.uShift, 0);
    
    VertexOut out;
    out.position = clipPosition;
    out.texCoord = texCoord;
    return out;
}

fragment float4 fragmentShaderGlobe(VertexOut in [[stage_in]],
                                    texture2d<float> colorTexture [[texture(0)]],
                                    sampler textureSampler[[sampler(0)]]) {
    float4 color = colorTexture.sample(textureSampler, in.texCoord);
    return color;
}
