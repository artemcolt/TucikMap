//
//  Msdf.metal
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

#include <metal_stdlib>
using namespace metal;
#include "Common.h"


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
