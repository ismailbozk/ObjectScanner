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

struct OSMatch{
    var trainPoint: CGPoint;
    var queryPoint: CGPoint;
    
    init()
    {
        trainPoint = CGPointMake(0.0, 0.0);
        queryPoint = CGPointMake(0.0, 0.0);
    }
}