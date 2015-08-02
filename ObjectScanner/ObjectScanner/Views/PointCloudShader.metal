//
//  PointCloudShader.metal
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut pointCloudVertex (const device float4 *vertices [[buffer (0)]],
                                   const device Uniforms &uniforms [[buffer (1)]],
                                   unsigned int vid [[ vertex_id ]])
{
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    float4 vertexPoint = vertices[vid];
    
    VertexOut vertexOut;
    
    vertexPoint.z -= .5f;

//    float4x4 cameraPostionFixMatrix = float4x4(1.f);
//    cameraPostionFixMatrix[2][3] = -2.f;
//    
//    vertexPoint = cameraPostionFixMatrix * vertexPoint;
    
    vertexOut.position = uniforms.projectionMatrix * vertexPoint;
//    vertexOut.position = proj_Matrix * mv_Matrix * vertexPoint;
    
    
    
    vertexOut.position.x /= 4;
    vertexOut.position.y /= 4;
    vertexOut.position.z /= 4;
    
    
    if (vertexPoint.x < 1.f ||
        vertexPoint.y < 1.f ||
        vertexPoint.z < 1.f )
    {
        vertexOut.color = float4(1.f, 1.f, 1.f, 0.f);
    }
    else
    {
        vertexOut.color = float4(1.f, 1.f, 1.f, 1.f);
    }
        
    vertexOut.pointSize = 1.f;
    
    return vertexOut;
}

fragment half4 pointCloudFragment (VertexOut interpolated [[stage_in]])
{
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}