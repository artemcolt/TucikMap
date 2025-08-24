//
//  Msdf.metal
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"


float4 getGlobeWorldPosition(float2 normMapCoord, float radius, float longitude, float latitude) {
    float4 spherePos = float4(getSpherePos(normMapCoord, radius), 1);
    
    float4x4 globeTranslate = translation_matrix(float3(0, 0, -radius));
    float4x4 globeLongitude = rotation_matrix(-longitude, float3(0, 1, 0));
    float4x4 globeLatitude = rotation_matrix(latitude, float3(1, 0, 0));
    float4x4 globeRotation = globeLatitude * globeLongitude;
    float4 globeWorldLabelPos = globeTranslate * globeRotation * spherePos;
    return globeWorldLabelPos;
}

float3 getSpherePos(float2 normMapCoord, float radius) {
    constexpr float PI = M_PI_F;
    constexpr float HALF_PI = M_PI_F / 2.0;
    float theta = -normMapCoord.x * PI + HALF_PI;
    float y = normMapCoord.y * PI;
    float phi = 2.0 * atan(exp(y)) - HALF_PI;
    
    float3 spherePos;
    spherePos.x = radius * cos(phi) * cos(theta);
    spherePos.y = radius * sin(phi);
    spherePos.z = radius * cos(phi) * sin(theta);
    
    return spherePos;
}

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

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

// Функция для создания матрицы масштабирования
float4x4 scale_matrix(float3 scale) {
    return float4x4(
        float4(scale.x, 0.0f, 0.0f, 0.0f),
        float4(0.0f, scale.y, 0.0f, 0.0f),
        float4(0.0f, 0.0f, scale.z, 0.0f),
        float4(0.0f, 0.0f, 0.0f, 1.0f)
    );
}


float latToMercatorY(float latitudeRadians) {
    float sin_phi = sin(latitudeRadians);
    // Обработка крайних случаев: если |sin_phi| близко к 1, ограничить, чтобы избежать NaN/inf
    sin_phi = clamp(sin_phi, -0.999999f, 0.999999f);
    float log_term = log((1.0f + sin_phi) / (1.0f - sin_phi));
    float y_proj = 0.5f * log_term;
    float y_norm = y_proj / M_PI_F;
    return y_norm;
}
