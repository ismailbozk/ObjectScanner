//
//  Shared.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 14/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

import simd
import UIKit


struct OSPoint {
    var point: float4 = float4(0.0);
    var color: float4 = float4(1.0);

    static let origin: OSPoint = OSPoint();

    
    func isValid() -> Bool
    {
        if  self.point.x == OSPoint.origin.point.x &&
            self.point.y == OSPoint.origin.point.y &&
            self.point.z == OSPoint.origin.point.z
        {
            return false;
        }
        return true;
    }
}

struct OSMatch3D {
    var trainPoint: float4
    var queryPoint: float4
    
    init()
    {
        self.queryPoint = float4(0.0, 0.0, 0.0, 1.0);
        self.trainPoint = float4(0.0, 0.0, 0.0, 1.0);
    }
    
    init(queryPoint: float4, trainPoint: float4)
    {
        self.queryPoint = queryPoint;
        self.trainPoint = trainPoint;
    }
//    var trainPoint: Vector4
//    var queryPoint: Vector4
//    
//    init()
//    {
//        self.queryPoint = Vector4(0.0, 0.0, 0.0, 1.0);
//        self.trainPoint = Vector4(0.0, 0.0, 0.0, 1.0);
//    }
//    
//    init(queryPoint: Vector4, trainPoint: Vector4)
//    {
//        self.queryPoint = queryPoint;
//        self.trainPoint = trainPoint;
//    }
}

struct OSMatch{
    var trainPoint: CGPoint;
    var queryPoint: CGPoint;
    
    init()
    {
        trainPoint = CGPointMake(0.0, 0.0);
        queryPoint = CGPointMake(0.0, 0.0);
    }
}