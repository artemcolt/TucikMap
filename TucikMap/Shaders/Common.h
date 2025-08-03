//
//  Common.h
//  TucikMap
//
//  Created by Artem on 6/10/25.
//

#ifndef COMMON
#define COMMON

float median(float r, float g, float b);

float4x4 translation_matrix(float3 translation);

float4x4 rotation_matrix(float angle, float3 axis);

float4x4 scale_matrix(float3 scale);

#endif
