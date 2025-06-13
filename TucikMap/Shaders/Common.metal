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

