//
//  OSRegistrationUtility.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 15/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSRegistrationUtility.h"

#import "Shared.h"

#ifdef __cplusplus
#include <opencv2/legacy/legacy.hpp>
#endif

@implementation OSRegistrationUtility

+ (NSData *)createTransformationMatrixWithMatches:(NSArray *)matches
{
    simd::float4x4 transformation = simd::float4x4();
    
    // Obtain mid points of matches and seperated consecutive matches
    simd::float4 trainMidPoint = {0.f,0.f,0.f,1.f};		//d_ mid
    simd::float4 testMidPoint = {0.f,0.f,0.f,1.f};		//m_ mid

    OSMatch3D match;
    for (int i = 0; i < matches.count; i++)
    {
        [((NSData *)matches[i]) getBytes:&match length:sizeof(OSMatch3D)];
        
        trainMidPoint += match.trainPoint;
        testMidPoint += match.queryPoint;
    }
    trainMidPoint.x = trainMidPoint.x / matches.count;
    trainMidPoint.y = trainMidPoint.y / matches.count;
    trainMidPoint.z = trainMidPoint.z / matches.count;
    trainMidPoint.w = 1.f;
    testMidPoint.x = testMidPoint.x / matches.count;
    testMidPoint.y = testMidPoint.y / matches.count;
    testMidPoint.z = testMidPoint.z / matches.count;
    testMidPoint.w = 1.f;
    
    // Pull the all points to around origin midpoints traslated to the 0,0,0 point and finding the H matrix
    float HMatrix11 = 0.0;
    float HMatrix12 = 0.0;
    float HMatrix13 = 0.0;
    float HMatrix21 = 0.0;
    float HMatrix22 = 0.0;
    float HMatrix23 = 0.0;
    float HMatrix31 = 0.0;
    float HMatrix32 = 0.0;
    float HMatrix33 = 0.0;
    
    for (int i = 0; i < matches.count; i++)
    {
        [((NSData *)matches[i]) getBytes:&match length:sizeof(OSMatch3D)];
        match.trainPoint -= trainMidPoint;
        match.queryPoint -= testMidPoint;
        
        HMatrix11 += match.trainPoint.x * match.queryPoint.x;
        HMatrix12 += match.trainPoint.x * match.queryPoint.y;
        HMatrix13 += match.trainPoint.x * match.queryPoint.z;
        
        HMatrix21 += match.trainPoint.y * match.queryPoint.x;
        HMatrix22 += match.trainPoint.y * match.queryPoint.y;
        HMatrix23 += match.trainPoint.y * match.queryPoint.z;
        
        HMatrix31 += match.trainPoint.z * match.queryPoint.x;
        HMatrix32 += match.trainPoint.z * match.queryPoint.y;
        HMatrix33 += match.trainPoint.z * match.queryPoint.z;

    }
    
    // SVD
    cv::Matx33f src = cv::Matx33f();
    
    src(0,0) = HMatrix11; src(0,1) = HMatrix12; src(0,2) = HMatrix13;
    src(1,0) = HMatrix21; src(1,1) = HMatrix22; src(1,2) = HMatrix23;
    src(2,0) = HMatrix31; src(2,1) = HMatrix32; src(2,2) = HMatrix33;
    
    cv::Matx31f w;
    cv::Matx33f u;
    cv::Matx33f vt;
    cv::SVD::compute(src, w, u, vt, 0);

    // Transformation
    // Rotation
    (transformation).columns[0][0] = vt(0,0);
    (transformation).columns[0][1] = vt(0,1);
    (transformation).columns[0][2] = vt(0,2);
    (transformation).columns[0][3] = 0.0;
    
    (transformation).columns[1][0] = vt(1,0);
    (transformation).columns[1][1] = vt(1,1);
    (transformation).columns[1][2] = vt(1,2);
    (transformation).columns[1][3] = 0.0;
    
    (transformation).columns[2][0] = vt(2,0);
    (transformation).columns[2][1] = vt(2,1);
    (transformation).columns[2][2] = vt(2,2);
    (transformation).columns[2][3] = 0.0;
    
    (transformation).columns[3][0] = 0.0;
    (transformation).columns[3][1] = 0.0;
    (transformation).columns[3][2] = 0.0;
    (transformation).columns[3][3] = 1.0;

    // Translation
    simd::float4 translation;
    testMidPoint = transformation * testMidPoint;
    translation = trainMidPoint - testMidPoint;
    
    transformation.columns[3][0] = translation.x;
    transformation.columns[3][1] = translation.y;
    transformation.columns[3][2] = translation.z;
    transformation.columns[3][3] = 1.f;
    
    return[NSData dataWithBytes:&transformation length:sizeof(simd::float4x4)];
}

@end