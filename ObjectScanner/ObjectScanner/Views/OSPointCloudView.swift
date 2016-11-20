//
//  OSPointCloudView.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 01/08/2015.
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
import Metal
import QuartzCore

struct Uniforms {
    var viewMatrix : Matrix4 = Matrix4.Identity;
    var projectionMatrix : Matrix4 = Matrix4.Identity;
}

let kOSPointCloudViewVelocityScale: CGFloat = 0.01;
let kOSPointCloudViewDamping: CGFloat = 0.05;

let kOSPointCloudViewXAxis: Vector3 = Vector3(1.0, 0.0, 0.0);
let kOSPointCloudViewYAxis: Vector3 = Vector3(0.0, 1.0, 0.0);

class OSPointCloudView: UIView, OSContentLoadingProtocol{
    fileprivate let panGestureRecognizer: UIGestureRecognizer = UIPanGestureRecognizer();
    fileprivate var angularVelocity: CGPoint = CGPoint.zero;
    fileprivate var angle: CGPoint = CGPoint.zero;
    fileprivate var lastFrameTime: TimeInterval = 0.0;
    
    fileprivate var metalLayer: CAMetalLayer! = nil;
    
    fileprivate static let device: MTLDevice = MTLCreateSystemDefaultDevice()!;
    fileprivate static let commandQueue: MTLCommandQueue = OSPointCloudView.device.makeCommandQueue();
    fileprivate static var pipelineState: MTLRenderPipelineState?;
    fileprivate static var depthStencilState: MTLDepthStencilState?;
    fileprivate var timer: CADisplayLink?;
    
    fileprivate var isReadForAction = false;
    
    fileprivate var vertices: [OSPoint] = [OSPoint]();
    fileprivate let threadSafeConcurrentVertexAccessQueue = DispatchQueue(label: "OSPointCloudViewThreadSafeConcurrentVertexAccessQueue", attributes: DispatchQueue.Attributes.concurrent);
    fileprivate var vertexBuffer: MTLBuffer?;
    fileprivate let threadSafeConcurrentVertexBufferAccessQueue : DispatchQueue = DispatchQueue(label: "OSPointCloudViewThreadSafeConcurrentVertexBufferAccessQueue", attributes: DispatchQueue.Attributes.concurrent);//don't use that queue anywhere else other than custom getters and setters for vertexBuffer property.

    fileprivate var transformationMatrices: [Matrix4] = [Matrix4]();
    fileprivate var transformationBuffer: MTLBuffer?;
    fileprivate let threadSafeConcurrentTransformationBufferAccessQueue : DispatchQueue = DispatchQueue(label: "OSPointCloudViewThreadSafeConcurrentTransformationBufferAccessQueue", attributes: DispatchQueue.Attributes.concurrent);//don't use that queue anywhere else other than custom getters and setters for transformationBuffer property.
    
    fileprivate var uniforms: Uniforms = Uniforms();
    fileprivate var uniformBuffer: MTLBuffer?;
    
// MARK: Lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        
        panGestureRecognizer.addTarget(self, action: #selector(OSPointCloudView.gestureRecognizerDidRecognize(_:)));
        self .addGestureRecognizer(panGestureRecognizer);
        
        metalLayer = (self.layer as! CAMetalLayer);
        
        metalLayer.device = OSPointCloudView.device;
        metalLayer.pixelFormat = .bgra8Unorm;
        metalLayer.framebufferOnly = true;
        
        timer = CADisplayLink(target: self, selector: #selector(OSPointCloudView.tic(_:)))
        timer!.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        self.lastFrameTime = CFAbsoluteTimeGetCurrent();
    }
    
    override var frame: CGRect{
        didSet {
            if (self.metalLayer != nil)
            {
                let scale : CGFloat = UIScreen.main.scale;
                self.metalLayer.drawableSize = CGSize(width: self.bounds.width * scale, height: self.bounds.height * scale);
            }
        }
    }
    
    deinit
    {
        self.timer?.invalidate();
    }
    
    override class var layerClass : AnyClass
    {
        return CAMetalLayer.self;
    }
    
// MARK: Display methods
    
    func tic(_ displayLink: CADisplayLink)
    {
        if (self.isReadForAction == true)
        {
            self.updateMotion();
            self.updateUniforms();

            if  let drawable = metalLayer.nextDrawable(),
                let tempVertexBuffer = self.getVertexBuffer(),
                let tempTransformationBuffer = self.getTransformationBuffer()
            {
                
                let vertexCount = self.getVertexArray()!.count;
                let renderPassDescriptor = MTLRenderPassDescriptor();
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0);
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                
                let commandBuffer = OSPointCloudView.commandQueue.makeCommandBuffer();
                
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor);
                renderEncoder.setFrontFacing(MTLWinding.counterClockwise)
                renderEncoder.setCullMode(MTLCullMode.front);
                
                renderEncoder.setRenderPipelineState(OSPointCloudView.pipelineState!);
                
                renderEncoder.setDepthStencilState(OSPointCloudView.depthStencilState);//this will prevents the points, that should appear farther away, to be drawn on top of the other points, which are closer to the camera.
                
                renderEncoder.setVertexBuffer(tempVertexBuffer, offset: 0, at: 0);
                
                renderEncoder.setVertexBuffer(tempTransformationBuffer, offset: 0, at: 2);
                
                renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, at: 1);
                
                renderEncoder.drawPrimitives(type: MTLPrimitiveType.point, vertexStart: 0, vertexCount: vertexCount);
                renderEncoder.endEncoding();
                
                
                commandBuffer.present(drawable);
                commandBuffer.commit()
            }
        }
    }
    
    fileprivate func updateMotion()
    {
        let frameTime = CFAbsoluteTimeGetCurrent();
        let frameDuration =  CGFloat(frameTime - self.lastFrameTime);
        self.lastFrameTime = frameTime;
        
        if (frameDuration > 0.0)
        {
            self.angle = CGPoint(x: self.angle.x + self.angularVelocity.x * frameDuration, y: self.angle.y + self.angularVelocity.y * frameDuration);
            self.angularVelocity = CGPoint(x: self.angularVelocity.x * (1 - kOSPointCloudViewDamping), y: self.angularVelocity.y * (1 - kOSPointCloudViewDamping));
        }
    }
    
    fileprivate func updateUniforms()
    {
        var viewMatrix = Matrix4.Identity;
        
        viewMatrix = Matrix4.rotation(axis: kOSPointCloudViewYAxis, angle: Scalar(self.angle.x)) * viewMatrix;
        viewMatrix = Matrix4.rotation(axis: kOSPointCloudViewXAxis, angle: Scalar(self.angle.y)) * viewMatrix;
        
        let near: Float = 0.1;
        let far: Float = 100.0;
        let aspect: Float = Float(self.bounds.size.width / self.bounds.size.height);
        let projectionMatrix = Matrix4.perspectiveProjection(aspect: aspect, fovy: Float.degToRad(95.0), near: near, far: far);
        
        var uniforms: Uniforms = Uniforms();
        uniforms.viewMatrix = viewMatrix;
        
        let modelViewProj: Matrix4 = projectionMatrix
        uniforms.projectionMatrix = modelViewProj;
        
        self.uniforms = uniforms;
        
        self.uniformBuffer = OSPointCloudView.device.makeBuffer(bytes: &self.uniforms, length: MemoryLayout<Uniforms>.size, options:MTLResourceOptions.cpuCacheModeWriteCombined);
    }

// MARK: Custom Getter/Setters
    
    func getVertexBuffer() -> MTLBuffer?
    {
        var vertexBuffer : MTLBuffer?;
        (self.threadSafeConcurrentVertexBufferAccessQueue).sync { () -> Void in
            vertexBuffer = self.vertexBuffer;
        };
        return vertexBuffer;
    }
    
    func getTransformationBuffer() -> MTLBuffer?
    {
        var transformationBuffer: MTLBuffer?;
        (self.threadSafeConcurrentTransformationBufferAccessQueue).sync { () -> Void in
            transformationBuffer = self.transformationBuffer;
        };
        return transformationBuffer;
    }
    
    func setVertexBuffers(vertexBuffer: MTLBuffer, transformationBuffer: MTLBuffer)
    {
        self.threadSafeConcurrentVertexBufferAccessQueue.async(flags: .barrier, execute: { () -> Void in
            self.vertexBuffer = vertexBuffer;
            self.transformationBuffer = transformationBuffer;
        }) ;
    }
    
    func getVertexArray() -> [OSPoint]?
    {
        var vertexArray: [OSPoint]?
        self.threadSafeConcurrentVertexAccessQueue.sync { () -> Void in
            vertexArray = self.vertices;
        }
        return vertexArray;
    }

    func setVertexArray(_ vertexArray: [OSPoint])
    {
        self.threadSafeConcurrentVertexAccessQueue.async(flags: .barrier, execute: { () -> Void in
            self.vertices = vertexArray;
        }) ;
    }
    
// MARK: Publics
    
    func appendFrame(_ frame: OSBaseFrame)
    {
            self.transformationMatrices.append(frame.transformationMatrix);
            let transformationBuffer = OSPointCloudView.device.makeBuffer(bytes: self.transformationMatrices, length: self.transformationMatrices.count * MemoryLayout<Matrix4>.size, options: []);
            
//            self.setVertexArray(self.vertices + frame.pointCloud);
            self.vertices += frame.pointCloud;
            
            let vertexBuffer = OSPointCloudView.device.makeBuffer(bytes: self.getVertexArray()!, length: self.getVertexArray()!.count * MemoryLayout<OSPoint>.size, options: []);
            self.setVertexBuffers(vertexBuffer: vertexBuffer, transformationBuffer: transformationBuffer);
        self.isReadForAction = true;
    }
    
// MARK: Gesture Recogniser
    func gestureRecognizerDidRecognize(_ recogniser : UIPanGestureRecognizer)
    {
        let velocity: CGPoint = recogniser.velocity(in: self);
        self.angularVelocity = CGPoint(x: velocity.x * kOSPointCloudViewVelocityScale, y: velocity.y * kOSPointCloudViewVelocityScale);
    }
    
// MARK: OSContentLoadingProtocol
    
    static func loadContent(_ completionHandler: (() -> Void)!)
    {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { () -> Void in
            OSPointCloudView.device;
            
            OSPointCloudView.commandQueue;
            
            if (OSPointCloudView.pipelineState == nil)
            {
                let defaultLibrary = OSPointCloudView.device.newDefaultLibrary();
                let vertexFunction = defaultLibrary!.makeFunction(name: "pointCloudVertex");
                let fragmentFunction = defaultLibrary!.makeFunction(name: "pointCloudFragment");
                
                let pipelineStateDescriptor = MTLRenderPipelineDescriptor();
                pipelineStateDescriptor.vertexFunction = vertexFunction;
                pipelineStateDescriptor.fragmentFunction = fragmentFunction;
                pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm;
                
                do{
                    OSPointCloudView.pipelineState = try OSPointCloudView.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor);
                } catch _ {
                    OSPointCloudView.pipelineState = nil;
                    print("Failed to create pipeline state.");
                    
                };
                
                
                let depthStencilDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor();
                depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.less;
                
                depthStencilDescriptor.isDepthWriteEnabled = true;
                
                OSPointCloudView.depthStencilState = OSPointCloudView.device.makeDepthStencilState(descriptor: depthStencilDescriptor);

            }
            DispatchQueue.main.sync { () -> Void in
                completionHandler?();
            };
        };
    }
}
