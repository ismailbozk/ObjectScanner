//
//  Shared.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 09/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#ifndef Shared_h
#define Shared_h

#include <simd/simd.h>

typedef struct
{
    simd::float4 point;
    simd::float4 color;
}OSPoint;

typedef struct
{
    simd::float4 trainPoint;
    simd::float4 queryPoint;
}OSMatch3D;

#endif /* Shared_h */
