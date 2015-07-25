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

private let dummyDataSize : Int = 307200;


struct OSPoint {
    var x : Float = 0.0;
    var y : Float = 0.0;
    var z : Float = 0.0;
    var t : Float = 1.0;
}

class OSBaseFrame : OSContentLoadingProtocol{
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
    private var notCalibratedDepth: [Float] = [Float](count: dummyDataSize, repeatedValue: -1.0);
    
    var pointCloud : [OSPoint] = [OSPoint](count: dummyDataSize, repeatedValue: OSPoint());
    
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
    
    static private let device : MTLDevice = MTLCreateSystemDefaultDevice()!;
    static private let commandQueue : MTLCommandQueue = device.newCommandQueue();
    static private let defaultLibrary : MTLLibrary = device.newDefaultLibrary()!;
    static private let calibrateFrameFunction : MTLFunction = defaultLibrary.newFunctionWithName("calibrateFrame")!;
    static private var metalComputePipelineState : MTLComputePipelineState?;//very costly
    
    private var commandBuffer : MTLCommandBuffer?;
    private var computeCommandEncoder : MTLComputeCommandEncoder?;
    
    private func prepareMetalForSurgery()
    {
        let startTime = CACurrentMediaTime();

        OSTimer.tic();
        OSBaseFrame.device ;//= MTLCreateSystemDefaultDevice()!;
        OSTimer.toc("Device created");
        
        OSTimer.tic();
        OSBaseFrame.commandQueue ;//= device.newCommandQueue();
        OSTimer.toc("command queue created");
        
        OSTimer.tic();
        OSBaseFrame.defaultLibrary ;//= device.newDefaultLibrary();
        OSTimer.toc("default library");
        
        OSTimer.tic();
        OSBaseFrame.calibrateFrameFunction ;// = defaultLibrary?.newFunctionWithName("calibrateFrame");
        OSTimer.toc("frame funtion created");
        
        if (OSBaseFrame.metalComputePipelineState == nil)
        {
            OSTimer.tic();
            //FIXME very costly try to minimize the impact.
            do{
                OSBaseFrame.metalComputePipelineState = try OSBaseFrame.device.newComputePipelineStateWithFunction(OSBaseFrame.calibrateFrameFunction);
            } catch _ {
                OSBaseFrame.metalComputePipelineState = nil
            };
            //        self.metalComputePipelineState = self.device.newComputePipelineStateWithFunction(self.calibrateFrameFunction!);
            OSTimer.toc("compute pipeline creation");
        }
        
        
        
        OSTimer.tic();
        self.commandBuffer = OSBaseFrame.commandQueue.commandBuffer();
        OSTimer.toc("command buffer creation");
        
        OSTimer.tic();
        self.computeCommandEncoder = self.commandBuffer?.computeCommandEncoder();
        OSTimer.toc("command encoder creation");
        
        OSTimer.tic();
        self.computeCommandEncoder?.setComputePipelineState(OSBaseFrame.metalComputePipelineState!);
        OSTimer.toc("command encoder set Pipeline");
        
        let dataSize : Int = self.notCalibratedDepth.count//self.height * self.width;

        OSTimer.tic();
        let inputByteLength = dataSize * sizeof(Float);
        let inVectorBuffer = OSBaseFrame.device.newBufferWithBytes(&self.notCalibratedDepth, length: inputByteLength, options:[]);
        self.computeCommandEncoder?.setBuffer(inVectorBuffer, offset: 0, atIndex: 0);

        let outputByteLength = dataSize * sizeof(OSPoint);
        let outputBuffer = OSBaseFrame.device.newBufferWithBytes(&self.pointCloud, length: outputByteLength, options: []);
        self.computeCommandEncoder?.setBuffer(outputBuffer, offset: 0, atIndex: 1);
        OSTimer.toc("passing data into buffers");
        
        
        OSTimer.tic();
        let threadGroupCountX = dataSize / 128;
        let threadGroupCount = MTLSize(width: threadGroupCountX, height: 1, depth: 1)
        let threadGroups = MTLSize(width:(dataSize + threadGroupCountX - 1) / threadGroupCountX, height:1, depth:1);
        
        self.computeCommandEncoder?.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroups);
        OSTimer.toc("compute command encoder setting thread groups");
        
        OSTimer.tic();
        self.computeCommandEncoder?.endEncoding();
        OSTimer.toc("compute command encoder end encoding");
        
        OSTimer.tic();
        self.commandBuffer?.commit();
        OSTimer.toc("command buffer commit");
        
        OSTimer.tic();
        self.commandBuffer?.waitUntilCompleted();
        OSTimer.toc("command buffer wait until completed IMPORTANT");
        
        OSTimer.tic();
        let data = NSData(bytesNoCopy: outputBuffer.contents(), length: self.pointCloud.count * sizeof(OSPoint), freeWhenDone: false);
        data.getBytes(&self.pointCloud, length: outputByteLength);
        OSTimer.toc("Reading data from gpu");
        
        var inputVectors2 = [Float](count: dataSize, repeatedValue: -1.0);
        let dataIn = NSData(bytesNoCopy: inVectorBuffer.contents(), length: inputByteLength, freeWhenDone: false);
        dataIn.getBytes(&inputVectors2, length: inputByteLength);
        
        let elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
        
        NSLog("Total process %f seconds" ,elapsedTime);
    }
    
    func unitTest(multiplier : Float)
    {
        for (var x : Int = 0; x < self.notCalibratedDepth.count; x++)
        {
            self.notCalibratedDepth[x] = Float(x) * multiplier;
        }
        
        self.prepareMetalForSurgery();
    }
    
    init()
    {
//        OSBaseFrame.loadContent();
    }

    
    static func loadContent(completionHandler : (() -> Void)!)
    {
        OSTimer.tic();
        OSBaseFrame.device ;//= MTLCreateSystemDefaultDevice()!;
        OSTimer.toc("Device created");
        
        OSTimer.tic();
        OSBaseFrame.commandQueue ;//= device.newCommandQueue();
        OSTimer.toc("command queue created");
        
        OSTimer.tic();
        OSBaseFrame.defaultLibrary ;//= device.newDefaultLibrary();
        OSTimer.toc("default library");
        
        OSTimer.tic();
        OSBaseFrame.calibrateFrameFunction ;// = defaultLibrary?.newFunctionWithName("calibrateFrame");
        OSTimer.toc("frame funtion created");
        
        if (OSBaseFrame.metalComputePipelineState == nil)
        {
            OSTimer.tic();
            //FIXME very costly try to minimize the impact.
            do{
                OSBaseFrame.metalComputePipelineState = try OSBaseFrame.device.newComputePipelineStateWithFunction(OSBaseFrame.calibrateFrameFunction);
            } catch _ {
                OSBaseFrame.metalComputePipelineState = nil
            };
            OSTimer.toc("compute pipeline creation");
        }
        
        
        completionHandler();
    }
}
