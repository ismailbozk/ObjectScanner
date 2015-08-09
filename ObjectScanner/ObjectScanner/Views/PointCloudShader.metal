//
//  PointCloudShader.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
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