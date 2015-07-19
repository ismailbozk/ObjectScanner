//
//  OSBaseFrame.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

//import Cocoa
import UIKit
import simd
import Accelerate

struct OSPoint {
    var x : Float = 0.0;
    var y : Float = 0.0;
    var z : Float = 0.0;
    var t : Float = 1.0;
    
    private (set) var r : Float = 0.0;    //between 0 and 1
    private (set) var g : Float = 0.0;
    private (set) var b : Float = 0.0;

//    init(x:Float, y:Float, z:Float, r:Float, g:Float, b:Float){
//        self.x = x;
//        self.y = y;
//        self.z = z;
//        
//        self.r = r;
//        self.g = g;
//        self.b = b;
//    }
}

class OSBaseFrame {
    let image : UIImage;
    var height : Int{
        get {
            return (Int)(self.image.size.height);
        }
    }
    var width : Int{
        get{
            return (Int)(self.image.size.width);
        }
    }
    private (set) var calibratedDepth : [Float];
    private var notCalibratedDepth: [Float];
    
    var pointCloud : [OSPoint];
    
    init(image :UIImage, depth: [Float]){
        var size : Int = (Int)(image.size.width) * (Int)(image.size.height)

        assert(size == depth.count, "depth frame and image must be equal size");
        
        self.image = image;
        self.notCalibratedDepth = depth;
        self.calibratedDepth = [Float](count: depth.count, repeatedValue: -1.0);//-1 will be the invalid depth data value
        self.pointCloud = [OSPoint](count: size, repeatedValue: OSPoint());
    }
    
    subscript(row : Int, col : Int) -> OSPoint{
        get {
            return self.pointCloud[row * self.width + col];
        }
//        set (newValue) {
//            self.pointCloud[row * self.width + col] = newValue;
//        }
    }
}
