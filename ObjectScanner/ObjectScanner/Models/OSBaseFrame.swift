//
//  OSBaseFrame.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit

struct OSPoint {
    var x : Float = 0.0;
    var y : Float = 0.0;
    var z : Float = 0.0;
    var t : Float = 1.0;
}

private var calibrationMatrix : [Float] = [9.9984628826577793e-01 , 1.2635359098409581e-03 , -1.7487233004436643e-02, 0,
                                           -1.4779096108364480e-03, 9.9992385683542895e-01 , -1.2251380107679535e-02, 0,
                                           1.7470421412464927e-02 , 1.2275341476520762e-02 , 9.9977202419716948e-01 , 0,
                                           1.9985242312092553e-02 , -7.4423738761617583e-04, -1.0916736334336222e-02,1];

//90 degree counter clockwise rotaion on z axis + -1 translation x axis
//private var calibrationMatrix : [Float] = [0 , 1 , 0, 0,
//    -1, 0 , 0, 0,
//    0 , 0 , 0 , 0,
//    -1 , 0, 0, 1];

class OSBaseFrame : OSContentLoadingProtocol{
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
//    private (set) var calibratedDepth : [Float];
    private var notCalibratedDepth: [Float];
    
    var pointCloud : [OSPoint];
    
    required init(image :UIImage, depth: [Float]){
        let size : Int = (Int)(image.size.width) * (Int)(image.size.height)

        assert(size == depth.count, "depth frame and image must be equal size");
        
        self.image = image;
        self.notCalibratedDepth = depth;
//        self.calibratedDepth = [Float](count: depth.count, repeatedValue: -1.0);//-1 will be the invalid depth data value
        self.pointCloud = [OSPoint](count: size, repeatedValue: OSPoint());
    }
    
//    subscript(row : Int, col : Int) -> OSPoint{
//        get {
//            return (self.pointCloud[row * self.width + col]);
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
    
    static private var calibrationMatrixBuffer : MTLBuffer?;
    
    private var commandBuffer : MTLCommandBuffer?;
    private var computeCommandEncoder : MTLComputeCommandEncoder?;
    
    func preparePointCloud(completionHandler : (() -> Void)!)
    {
        let startTime = CACurrentMediaTime();
        
        self.commandBuffer = OSBaseFrame.commandQueue.commandBuffer();
        
        self.computeCommandEncoder = self.commandBuffer?.computeCommandEncoder();
        
        self.computeCommandEncoder?.setComputePipelineState(OSBaseFrame.metalComputePipelineState!);
        
        //pass the data to GPU
        let dataSize : Int = self.notCalibratedDepth.count//self.height * self.width;

        let inputByteLength = dataSize * sizeof(Float);
        let inVectorBuffer = OSBaseFrame.device.newBufferWithBytes(&self.notCalibratedDepth, length: inputByteLength, options:[]);
        self.computeCommandEncoder?.setBuffer(inVectorBuffer, offset: 0, atIndex: 0);
        let outputByteLength = dataSize * sizeof(OSPoint);
        let outputBuffer = OSBaseFrame.device.newBufferWithBytes(&self.pointCloud, length: outputByteLength, options: []);
        self.computeCommandEncoder?.setBuffer(outputBuffer, offset: 0, atIndex: 1);
        self.computeCommandEncoder?.setBuffer(OSBaseFrame.calibrationMatrixBuffer, offset: 0, atIndex: 2);
        
        //prepare thread groups
        let threadGroupCountX = dataSize / 512;
        let threadGroupCount = MTLSize(width: threadGroupCountX, height: 1, depth: 1)
        let threadGroups = MTLSize(width:(dataSize + threadGroupCountX - 1) / threadGroupCountX, height:1, depth:1);
        
        self.computeCommandEncoder?.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroups);
        
        self.computeCommandEncoder?.endEncoding();
        
        self.commandBuffer?.addCompletedHandler({ (commandBuffer : MTLCommandBuffer) -> Void in
            let data = NSData(bytesNoCopy: outputBuffer.contents(), length: (self.pointCloud.count) * sizeof(OSPoint), freeWhenDone: false);
            data.getBytes(&self.pointCloud, length: outputByteLength);
            
            let elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
            print("Total process \(elapsedTime) seconds");
            
            completionHandler?();
        });
        
        self.commandBuffer?.commit();
    }
    
// MARK: OSContentLoadingProtocol

    static func loadContent(completionHandler : (() -> Void)!)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
            OSBaseFrame.device ;
            
            OSBaseFrame.commandQueue ;
            
            OSBaseFrame.defaultLibrary ;
            
            OSBaseFrame.calibrateFrameFunction ;
            
            let calibrationMatrixBtyeLength = calibrationMatrix.count * sizeof(Float);
            calibrationMatrixBuffer = OSBaseFrame.device.newBufferWithBytes(&calibrationMatrix, length: calibrationMatrixBtyeLength, options: []);
            
            if (OSBaseFrame.metalComputePipelineState == nil)
            {
                do{
                    OSBaseFrame.metalComputePipelineState = try OSBaseFrame.device.newComputePipelineStateWithFunction(OSBaseFrame.calibrateFrameFunction);
                } catch _ {
                    OSBaseFrame.metalComputePipelineState = nil
                };
            }
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                completionHandler?();
            };
        };
    }
}
