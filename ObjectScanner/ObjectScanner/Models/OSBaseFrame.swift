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

struct OSPointIn {
    var x : Int32 = 0;
    var y : Int32 = 0;
    
    var depth : Float = -1.0;
}

struct OSPoint {
    var x : Float = 0.0;
    var y : Float = 0.0;
    var z : Float = 0.0;
    var t : Float = 1.0;
    
//    private (set) var r : Float = 0.0;    //between 0 and 1
//    private (set) var g : Float = 0.0;
//    private (set) var b : Float = 0.0;

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
//    let image : UIImage;
//    var height : Int{
//        get {
//            return (Int)(self.image.size.height);
//        }
//    }
//    var width : Int{
//        get{
//            return (Int)(self.image.size.width);
//        }
//    }
//    private (set) var calibratedDepth : [Float];
    private var notCalibratedDepth: [Float] = [Float](count: 128, repeatedValue: -1.0);
    
    var pointCloud : [OSPoint] = [OSPoint](count: 128, repeatedValue: OSPoint());
    
//    init(image :UIImage, depth: [Float]){
//        var size : Int = (Int)(image.size.width) * (Int)(image.size.height)
//
//        assert(size == depth.count, "depth frame and image must be equal size");
//        
//        self.image = image;
//        self.notCalibratedDepth = depth;
//        self.calibratedDepth = [Float](count: depth.count, repeatedValue: -1.0);//-1 will be the invalid depth data value
//        self.pointCloud = [OSPoint](count: size, repeatedValue: OSPoint());
//        
//        self.prepareMetalForSurgery();
//    }
    
//    subscript(row : Int, col : Int) -> OSPoint{
//        get {
//            return self.pointCloud[row * self.width + col];
//        }
////        set (newValue) {
////            self.pointCloud[row * self.width + col] = newValue;
////        }
//    }
    
    //MARK: Metal
    
    private let device : MTLDevice = MTLCreateSystemDefaultDevice();
    private var commandQueue : MTLCommandQueue?;
    private var defaultLibrary: MTLLibrary?;
    private var calibrateFrameFunction : MTLFunction?;
    private var metalComputePipelineState : MTLComputePipelineState?;//very costly
    private var commandBuffer : MTLCommandBuffer?;
    private var computeCommandEncoder : MTLComputeCommandEncoder?;
    
    private func prepareMetalForSurgery()
    {
        var startTime = CACurrentMediaTime();

        
        self.commandQueue = self.device.newCommandQueue();
        self.defaultLibrary = self.device.newDefaultLibrary();
        self.calibrateFrameFunction = self.defaultLibrary?.newFunctionWithName("calibrateFrame");
        //FIXME very costly try to minimize the impact.
        self.metalComputePipelineState = self.device.newComputePipelineStateWithFunction(self.calibrateFrameFunction!, error: nil);
        self.commandBuffer = self.commandQueue?.commandBuffer();
        self.computeCommandEncoder = self.commandBuffer?.computeCommandEncoder();
        self.computeCommandEncoder?.setComputePipelineState(self.metalComputePipelineState!);
        
        let dataSize : Int = 128//self.height * self.width;
        
        var inputVetors : [OSPointIn] = [OSPointIn](count: dataSize, repeatedValue: OSPointIn());
        
        var x : Int32 = 0;
        var y : Int32 = 0;
        var depth : Float = 0.0;
        for (var pos : Int = 0; pos < dataSize; pos++)
        {
            x = Int32(pos % 8)//self.width;
            y = Int32(pos % 16)//self.width;
            depth = self.notCalibratedDepth[pos];
            inputVetors[pos].x = x;
            inputVetors[pos].y = y;
            inputVetors[pos].depth = depth;
        }
        
        let inputByteLength = dataSize * sizeofValue(inputVetors[0]);
        let i2 = dataSize * sizeof(OSPointIn);
        var inVectorBuffer = self.device.newBufferWithBytes(&inputVetors, length: inputByteLength, options: nil);
        self.computeCommandEncoder?.setBuffer(inVectorBuffer, offset: 0, atIndex: 0);

        let outputByteLength = dataSize * sizeofValue(self.pointCloud[0]);
        let o2 = dataSize * sizeof(OSPoint);
        var outputBuffer = self.device.newBufferWithBytes(&self.pointCloud, length: outputByteLength, options: nil);
        self.computeCommandEncoder?.setBuffer(outputBuffer, offset: 0, atIndex: 1);
        
        let threadGroupCountX = 32;
        var threadGroupCount = MTLSize(width: threadGroupCountX, height: 1, depth: 1)
        var threadGroups = MTLSize(width:(dataSize + threadGroupCountX - 1) / threadGroupCountX, height:1, depth:1);
        
        self.computeCommandEncoder?.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroups);
        
        self.computeCommandEncoder?.endEncoding();
        self.commandBuffer?.commit();
        self.commandBuffer?.waitUntilCompleted();
        
        var data = NSData(bytesNoCopy: outputBuffer.contents(), length: self.pointCloud.count * sizeof(OSPoint), freeWhenDone: false);
        data.getBytes(&self.pointCloud, length: outputByteLength);
        
        
        var inputVectors2 = [OSPointIn](count: dataSize, repeatedValue: OSPointIn());
        var dataIn = NSData(bytesNoCopy: inVectorBuffer.contents(), length: inputByteLength, freeWhenDone: false);
        dataIn.getBytes(&inputVectors2, length: inputByteLength);
        
        var elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
        
        NSLog("depth frames written in %f seconds" ,elapsedTime);
    }
    
    func unitTest()
    {
        self.notCalibratedDepth = [Float](count: 128, repeatedValue: -1.0);
        for (var x : Int = 0; x < self.notCalibratedDepth.count; x++)
        {
            self.notCalibratedDepth[x] = Float(x);
        }
        self.pointCloud = [OSPoint](count: 128, repeatedValue: OSPoint());
        
        self.prepareMetalForSurgery();
    }
    
    init()
    {
        
    }

}
