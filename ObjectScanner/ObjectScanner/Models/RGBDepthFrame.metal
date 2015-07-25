//
//  RGBDepthFrame.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant float fx_rgb = 5.2921508098293293e+02;
constant float fy_rgb = 5.2556393630057437e+02;
constant float cx_rgb = 3.2894272028759258e+02;
constant float cy_rgb = 2.6748068171871557e+02;

constant float fx_d = 1.0 / 5.9421434211923247e+02;
constant float fy_d = 1.0 / 5.9104053696870778e+02;
constant float cx_d = 3.3930780975300314e+02;
constant float cy_d = 2.4273913761751615e+02;

constant uint width = 640;
constant uint height = 480;

//struct OSPointIn {
//    int x;
//    int y;
//    
//    float depth;
//};

struct OSPoint {
    float x;
    float y;
    float z;
    float t;
    
//    float r;    //between 0 and 1
//    float g;
//    float b;
};

kernel void calibrateFrame(const constant float *depthValues [[buffer(0)]],
                           device OSPoint *outputPointCloud [[buffer(1)]],
                           const uint id [[thread_position_in_grid]])
{
    uint x = id % width;
    uint y = id / width;
    outputPointCloud[id].x = x;
    outputPointCloud[id].y = y;
    
    if (id > 1)
    {
        outputPointCloud[id].z = depthValues[id-1];
    }
    else
    {
        outputPointCloud[id].z = depthValues[id];
    }
}