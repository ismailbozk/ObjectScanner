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
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut pointCloudVertex (const device float4 *vertices [[buffer (0)]],
                                   const device Uniforms &uniforms [[buffer (1)]],
                                   texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                                   unsigned int vid [[ vertex_id ]])
{
    float4 vertexPoint = vertices[vid];
    
    VertexOut vertexOut;

    // Point Cloud registration
    
    
    // Rotate the pointcloud
    vertexPoint.z -= 2.f;//center point should be near 0.0 point
    vertexPoint = uniforms.viewMatrix * vertexPoint;
    vertexPoint.z += 2.f;
    
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
    uint2 gid;
    gid.x = vid % inTexture.get_width();
    gid.y = vid / inTexture.get_width();
    vertexOut.color = inTexture.read(gid);
    
    // Set the point size in the space
    vertexOut.pointSize = 0.5f;// currently for only @2x retina screens.
    
    return vertexOut;
}

fragment float4 pointCloudFragment (VertexOut interpolated [[stage_in]])
{
    return interpolated.color;
    return float4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}