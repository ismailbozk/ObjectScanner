//
//  RGBDepthFrame.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

constant float fx_rgb = 5.2921508098293293e+02f;
constant float fy_rgb = 5.2556393630057437e+02f;
constant float cx_rgb = 3.2894272028759258e+02f;
constant float cy_rgb = 2.6748068171871557e+02f;

constant float fx_d = 1.0f / 5.9421434211923247e+02f;
constant float fy_d = 1.0f / 5.9104053696870778e+02f;
constant float cx_d = 3.3930780975300314e+02f;
constant float cy_d = 2.4273913761751615e+02f;

constant uint width = 640;
constant uint height = 480;

kernel void calibrateFrame(const constant float *depthValues [[buffer(0)]],
                           device float4 *outputPointCloud [[buffer(1)]],
                           const constant float4x4 &calibrationMatrix [[buffer(2)]],
                           const uint id [[thread_position_in_grid]])
{
//    switch (id)
//    {
//    case 0:
//            outputPointCloud[id] = float4(calibrationMatrix[0][0], calibrationMatrix[0][1], calibrationMatrix[0][2], calibrationMatrix[0][3]);
//        break;
//    case 1:
//            outputPointCloud[id] = float4(calibrationMatrix[1][0], calibrationMatrix[1][1], calibrationMatrix[1][2], calibrationMatrix[1][3]);
//        break;
//    case 2:
//            outputPointCloud[id] = float4(calibrationMatrix[2][0], calibrationMatrix[2][1], calibrationMatrix[2][2], calibrationMatrix[2][3]);
//        break;
//    case 3:
//            outputPointCloud[id] = float4(calibrationMatrix[3][0], calibrationMatrix[3][1], calibrationMatrix[3][2], calibrationMatrix[3][3]);
//        break;
//    default:
//        outputPointCloud[id] = calibrationMatrix * float4(0, -1, 0 ,1);
//        break;
//    }
    
    
    if (depthValues[id] > 1.f) //if the depth value is valid
    {
        //coordinates on depth frame
        uint x = id % width;
        uint y = id / width;
        
        //transform into 3D space
        float4 tempPoint;
        
        tempPoint.z = depthValues[id] / 1000.f; // mm to meter
        tempPoint.x = ((x - cx_d) * tempPoint.z * fx_d);
        tempPoint.y = ((y - cy_d) * tempPoint.z * fy_d);
        tempPoint.w = 1.f;
        
        //calibrate 3D point to rgb frame coordinates
        tempPoint = calibrationMatrix * tempPoint;
        
        //corresponding 2D rgb frame coordinates for calibrated 3D point
        float invZ = 1.f / tempPoint.z;
        
        x = ((tempPoint.x * fx_rgb * invZ) + cx_rgb) + 3.0f;//+3 and + 14.7 are just minor tuning values, have no meaning other than that.
        y = ((tempPoint.y * fy_rgb * invZ) + cy_rgb) + 14.7f;
        
        //the 3D points will be stored as y * width + x on 1D array.
        if (x < width
            && y < height)
        {//if the corresponding point is in the rgb frame coordinates
            outputPointCloud[y * width + x] = tempPoint;
        }
    }
}

