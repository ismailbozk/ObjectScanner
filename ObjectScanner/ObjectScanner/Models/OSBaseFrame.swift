//
//  OSBaseFrame.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Ismail Bozkurt
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import simd
import Metal

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
    fileprivate var notCalibratedDepth: [Float];
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
        self.pointCloud = [OSPoint](repeating: OSPoint(), count: size);
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
    
    static fileprivate let device : MTLDevice = MTLCreateSystemDefaultDevice()!;
    static fileprivate let commandQueue : MTLCommandQueue = device.makeCommandQueue();
    static fileprivate let defaultLibrary : MTLLibrary = device.newDefaultLibrary()!;
    static fileprivate let calibrateFrameFunction : MTLFunction = defaultLibrary.makeFunction(name: "calibrateFrame")!;
    static fileprivate var metalComputePipelineState : MTLComputePipelineState?;//very costly
    
    static fileprivate var calibrationMatrixBuffer : MTLBuffer?;
    
    fileprivate var commandBuffer : MTLCommandBuffer?;
    fileprivate var computeCommandEncoder : MTLComputeCommandEncoder?;
    
    func preparePointCloud(_ completionHandler : (() -> Void)!)
    {
        let startTime = CACurrentMediaTime();
        
        self.commandBuffer = OSBaseFrame.commandQueue.makeCommandBuffer();
        
        self.computeCommandEncoder = self.commandBuffer?.makeComputeCommandEncoder();
        
        self.computeCommandEncoder?.setComputePipelineState(OSBaseFrame.metalComputePipelineState!);
        
        //pass the data to GPU
        let dataSize : Int = self.notCalibratedDepth.count//self.height * self.width;

        let imageTextureBuffer = OSTextureProvider.texture(with: self.image, device: OSBaseFrame.device);
        self.computeCommandEncoder?.setTexture(imageTextureBuffer, at: 0);
        
        let inputByteLength = dataSize * MemoryLayout<Float>.size;
        let inVectorBuffer = OSBaseFrame.device.makeBuffer(bytes: &self.notCalibratedDepth, length: inputByteLength, options:[]);
        self.computeCommandEncoder?.setBuffer(inVectorBuffer, offset: 0, at: 0);
        let outputByteLength = dataSize * MemoryLayout<OSPoint>.size;
        let outputBuffer = OSBaseFrame.device.makeBuffer(bytes: &self.pointCloud, length: outputByteLength, options: []);
        self.computeCommandEncoder?.setBuffer(outputBuffer, offset: 0, at: 1);
        self.computeCommandEncoder?.setBuffer(OSBaseFrame.calibrationMatrixBuffer, offset: 0, at: 2);
        
        //prepare thread groups
        let threadGroupCountX = dataSize / 512;
        let threadGroupCount = MTLSize(width: threadGroupCountX, height: 1, depth: 1)
        let threadGroups = MTLSize(width:(dataSize + threadGroupCountX - 1) / threadGroupCountX, height:1, depth:1);
        
        self.computeCommandEncoder?.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroups);
        
        self.computeCommandEncoder?.endEncoding();
        
        self.commandBuffer?.addCompletedHandler({[unowned self] (commandBuffer : MTLCommandBuffer) -> Void in
            let data = NSData(bytesNoCopy: outputBuffer.contents(), length: (self.pointCloud.count) * MemoryLayout<OSPoint>.size, freeWhenDone: false);
            data.getBytes(&self.pointCloud, length: outputByteLength);
            
            let elapsedTime : CFTimeInterval = CACurrentMediaTime() - startTime;
            print("Total process \(elapsedTime) seconds");
            
            completionHandler?();
        });
        
        self.commandBuffer?.commit();
    }
    
// MARK: OSContentLoadingProtocol

    static func loadContent(_ completionHandler : (() -> Void)!)
    {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { () -> Void in
            OSBaseFrame.device
            
            OSBaseFrame.commandQueue
            
            OSBaseFrame.defaultLibrary
            
            OSBaseFrame.calibrateFrameFunction
            
            let calibrationMatrixBtyeLength = calibrationMatrix.count * MemoryLayout<Float>.size;
            calibrationMatrixBuffer = OSBaseFrame.device.makeBuffer(bytes: &calibrationMatrix, length: calibrationMatrixBtyeLength, options: []);
            
            if (OSBaseFrame.metalComputePipelineState == nil)
            {
                do{
                    OSBaseFrame.metalComputePipelineState = try OSBaseFrame.device.makeComputePipelineState(function: OSBaseFrame.calibrateFrameFunction);
                } catch _ {
                    OSBaseFrame.metalComputePipelineState = nil
                };
            }
            DispatchQueue.main.sync { () -> Void in
                completionHandler?();
            };
        };
    }
}
