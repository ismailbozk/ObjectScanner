//
//  OSBaseFrame.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit
import simd

/// Single point representaion in 3D space. Look also Shared.h.


/// calibration matrix that calibrate depth frames onto rgb frame.
private var calibrationMatrix : [Float] = [9.9984628826577793e-01 , 1.2635359098409581e-03 , -1.7487233004436643e-02, 0,
                                           -1.4779096108364480e-03, 9.9992385683542895e-01 , -1.2251380107679535e-02, 0,
                                           1.7470421412464927e-02 , 1.2275341476520762e-02 , 9.9977202419716948e-01 , 0,
                                           1.9985242312092553e-02 , -7.4423738761617583e-04, -1.0916736334336222e-02,1];

/**
This class represents a single Kinect camera frame.
It also constains the calibration process and the result point cloud in 3D space.
*/
class OSBaseFrame : OSContentLoadingProtocol{
// MARK: Properties
    
    /// RGB Image of the frame
    let image : UIImage;
    /// Height of the frame
    var height : Int{
        get {
            return (Int)(self.image.size.height);
        }
    }
    /// Width of the frame
    var width : Int{
        get{
            return (Int)(self.image.size.width);
        }
    }
    /// Raw depth frame
    private var notCalibratedDepth: [Float];
    /// Calibrated but not transformed point cloud in 3D space
    var pointCloud: [OSPoint];
    /// Transformation matrix of the current frame in 3D space. This matrix trnasforms the current point cloud respect to the initial frame.
    var transformationMatrix: Matrix4 = Matrix4.Identity;
    
// MARK: Lifecycle
    required init(image :UIImage, depth: [Float]){
        let size : Int = (Int)(image.size.width) * (Int)(image.size.height)

        assert(size == depth.count, "depth frame and image must be equal size");
        
        self.image = image;
        self.notCalibratedDepth = depth;
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

        let imageTextureBuffer = OSTextureProvider.textureWithImage(self.image, device: OSBaseFrame.device);
        self.computeCommandEncoder?.setTexture(imageTextureBuffer, atIndex: 0);
        
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
        
        self.commandBuffer?.addCompletedHandler({[unowned self] (commandBuffer : MTLCommandBuffer) -> Void in
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
