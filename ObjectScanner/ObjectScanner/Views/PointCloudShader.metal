//
//  PointCloudShader.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
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

static constant float kPointCloudShaderDepthMean = 2.f;
static constant uint kPointCloudShaderSize = 307200;

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
};

struct Uniforms{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut pointCloudVertex (const device OSPoint *pointCloud [[buffer (0)]],
                                   const device float4x4 *transformationMatrices [[buffer (2)]],
                                   const device Uniforms &uniforms [[buffer (1)]],
                                   unsigned int vid [[ vertex_id ]])
{
    float4 vertexPoint = pointCloud[vid].point;
    
    VertexOut vertexOut;

    // Point Cloud registration
    uint frameIndex = vid / kPointCloudShaderSize;
    vertexPoint = transformationMatrices[frameIndex] * vertexPoint;
    
    // Rotate the pointcloud
    vertexPoint.z -= kPointCloudShaderDepthMean;//center point should be near 0.0 point
    vertexPoint = uniforms.viewMatrix * vertexPoint;
    vertexPoint.z += kPointCloudShaderDepthMean;
    
    
    /*
     Clip Space and Normalized Device Coordinates

     We need to make sure that the points produced by our projection transform are in the coordinate space it expects. Everything that is to be visible on the screen must be scaled down into a box that ranges from -1 to 1 in x, -1 to 1 in y, and 0 to 1 in z. This coordinate system is called clip space, and it’s where the hardware determines if triangles are completely visible, partially visible, or completely invisible. The edges of triangles that are partially visible are clipped against the planes of clip space. This clipping process may turn a triangle into a polygon, which is then re-triangulated to produce the geometry that gets fed to the fragment shader.
     */
    // put it into clip space
    vertexPoint.x = - vertexPoint.x;
    vertexPoint.y = - vertexPoint.y;
    vertexPoint.z = - vertexPoint.z;
    vertexPoint = uniforms.projectionMatrix * vertexPoint;
    vertexPoint.x /= 4;
    vertexPoint.y /= 4;
    vertexPoint.z /= 4;
    
    vertexOut.position = vertexPoint;

    // setting the color of the points
    vertexOut.color = pointCloud[vid].color;
    
    // Set the point size in the space
    vertexOut.pointSize = 0.5f;// currently for only @2x retina screens.
    
    return vertexOut;
}

fragment float4 pointCloudFragment (VertexOut interpolated [[stage_in]])
{
    return interpolated.color;
}
