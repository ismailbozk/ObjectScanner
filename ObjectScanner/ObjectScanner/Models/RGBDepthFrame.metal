//
//  RGBDepthFrame.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Ismail Bozkurt
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include <metal_stdlib>
#include "../Shared.h"

using namespace metal;

// Check pin camera model
// http://nicolas.burrus.name/index.php/Research/KinectCalibration

constant float fx_rgb = 5.2921508098293293e+02f;
constant float fy_rgb = 5.2556393630057437e+02f;
constant float cx_rgb = 3.2894272028759258e+02f;
constant float cy_rgb = 2.6748068171871557e+02f;

constant float fx_d = 1.0f / 5.9421434211923247e+02f;
constant float fy_d = 1.0f / 5.9104053696870778e+02f;
constant float cx_d = 3.3930780975300314e+02f;
constant float cy_d = 2.4273913761751615e+02f;

kernel void calibrateFrame(texture2d<float, access::read> image [[ texture(0) ]],
                           const constant float *depthValues [[buffer(0)]],
                           device OSPoint *outputPointCloud [[buffer(1)]],
                           const constant float4x4 &calibrationMatrix [[buffer(2)]],
                           const uint id [[thread_position_in_grid]])
{
    if (depthValues[id] > 1.f) //if the depth value is valid
    {
        uint width = image.get_width();
        
        // STEP 1: Find 3D Depth point by using 2D depth coordintates
        // Coordinates on depth frame
        uint x = id % width;
        uint y = id / width;
        
        //transform into 3D space
        float4 tempPoint;
        
        //check out pinhole camera model
        tempPoint.z = depthValues[id] / 1000.f; // mm to meter
        tempPoint.x = ((x - cx_d) * tempPoint.z * fx_d);
        tempPoint.y = ((y - cy_d) * tempPoint.z * fy_d);
        tempPoint.w = 1.f;
        
        
        // STEP 2: Align/Calibrate 3D Depth point on 3D real point (where we hold RGB data)
        // Calibrate 3D point to rgb frame coordinates
        tempPoint = calibrationMatrix * tempPoint;
        // Now depth and rgb camera 3D points are same
        
        
        // STEP 3: Reverse Step 1 on RGB point
        // Corresponding 2D rgb frame coordinates for calibrated 3D point
        float invZ = 1.f / tempPoint.z;
        
        x = ((tempPoint.x * fx_rgb * invZ) + cx_rgb) + 3.0f;//+3 and - 14.7 are just minor tuning values, have no meaning other than that.
        y = ((tempPoint.y * fy_rgb * invZ) + cy_rgb) - 14.7f;
        
        
        // STEP 4: store 3D points, so we can show them on device screen
        // The 3D points will be stored as y * width + x on 1D array.
        if (x < width
            && y < image.get_height())
        {//if the corresponding point is in the rgb frame coordinates
            int index = y * width + x;
            outputPointCloud[index].point = tempPoint;
            
            // setting the color of the points
            uint2 gridIndex;
            gridIndex.x = x;
            gridIndex.y = y;
            outputPointCloud[index].color = image.read(gridIndex);
        }
    }
}

