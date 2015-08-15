//
//  OSPointCloudView.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 01/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit

struct Uniforms {
    var viewMatrix : Matrix4 = Matrix4.Identity;
    var projectionMatrix : Matrix4 = Matrix4.Identity;
}

let kOSPointCloudViewVelocityScale: CGFloat = 0.01;
let kOSPointCloudViewDamping: CGFloat = 0.05;

let kOSPointCloudViewXAxis: Vector3 = Vector3(1.0, 0.0, 0.0);
let kOSPointCloudViewYAxis: Vector3 = Vector3(0.0, 1.0, 0.0);

class OSPointCloudView: UIView, OSContentLoadingProtocol{
    private let panGestureRecognizer: UIGestureRecognizer = UIPanGestureRecognizer();
    private var angularVelocity: CGPoint = CGPointZero;
    private var angle: CGPoint = CGPointZero;
    private var lastFrameTime: NSTimeInterval = 0.0;
    
    private var metalLayer: CAMetalLayer! = nil;
    
    private static let device: MTLDevice = MTLCreateSystemDefaultDevice()!;
    private static let commandQueue: MTLCommandQueue = OSPointCloudView.device.newCommandQueue();
    private static var pipelineState: MTLRenderPipelineState?;
    private static var depthStencilState: MTLDepthStencilState?;
    private var timer: CADisplayLink?;
    
    private var isReadForAction = false;
    
    private var vertices: [OSPoint] = [OSPoint]();
    private let threadSafeConcurrentVertexAccessQueue = dispatch_queue_create("OSPointCloudViewThreadSafeConcurrentVertexAccessQueue", DISPATCH_QUEUE_CONCURRENT);
    private var vertexBuffer: MTLBuffer?;
    private let threadSafeConcurrentVertexBufferAccessQueue : dispatch_queue_t = dispatch_queue_create("OSPointCloudViewThreadSafeConcurrentVertexBufferAccessQueue", DISPATCH_QUEUE_CONCURRENT);//don't use that queue anywhere else other than custom getters and setters for vertexBuffer property.

    private var transformationMatrices: [Matrix4] = [Matrix4]();
    private var transformationBuffer: MTLBuffer?;
    private let threadSafeConcurrentTransformationBufferAccessQueue : dispatch_queue_t = dispatch_queue_create("OSPointCloudViewThreadSafeConcurrentTransformationBufferAccessQueue", DISPATCH_QUEUE_CONCURRENT);//don't use that queue anywhere else other than custom getters and setters for transformationBuffer property.
    
    private var uniforms: Uniforms = Uniforms();
    private var uniformBuffer: MTLBuffer?;
    
// MARK: Lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        
        panGestureRecognizer.addTarget(self, action: Selector("gestureRecognizerDidRecognize:"));
        self .addGestureRecognizer(panGestureRecognizer);
        
        metalLayer = (self.layer as! CAMetalLayer);
        
        metalLayer.device = OSPointCloudView.device;
        metalLayer.pixelFormat = .BGRA8Unorm;
        metalLayer.framebufferOnly = true;
        
        timer = CADisplayLink(target: self, selector: Selector("tic:"))
        timer!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.lastFrameTime = CFAbsoluteTimeGetCurrent();
    }
    
    override var frame: CGRect{
        didSet {
            if (self.metalLayer != nil)
            {
                let scale : CGFloat = UIScreen.mainScreen().scale;
                self.metalLayer.drawableSize = CGSizeMake(self.bounds.width * scale, self.bounds.height * scale);
            }
        }
    }
    
    deinit
    {
        self.timer?.invalidate();
    }
    
    override class func layerClass() -> AnyClass
    {
        return CAMetalLayer.self;
    }
    
// MARK: Display methods
    
    func tic(displayLink: CADisplayLink)
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
                renderPassDescriptor.colorAttachments[0].loadAction = .Clear
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0);
                renderPassDescriptor.colorAttachments[0].storeAction = .Store
                
                let commandBuffer = OSPointCloudView.commandQueue.commandBuffer();
                
                let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor);
                renderEncoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
                renderEncoder.setCullMode(MTLCullMode.Front);
                
                renderEncoder.setRenderPipelineState(OSPointCloudView.pipelineState!);
                
                renderEncoder.setDepthStencilState(OSPointCloudView.depthStencilState);//this will prevents the points, that should appear farther away, to be drawn on top of the other points, which are closer to the camera.
                
                renderEncoder.setVertexBuffer(tempVertexBuffer, offset: 0, atIndex: 0);
                
                renderEncoder.setVertexBuffer(tempTransformationBuffer, offset: 0, atIndex: 2);
                
                renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 1);
                
                renderEncoder.drawPrimitives(MTLPrimitiveType.Point, vertexStart: 0, vertexCount: vertexCount);
                renderEncoder.endEncoding();
                
                
                commandBuffer.presentDrawable(drawable);
                commandBuffer.commit()
            }
        }
    }
    
    private func updateMotion()
    {
        let frameTime = CFAbsoluteTimeGetCurrent();
        let frameDuration =  CGFloat(frameTime - self.lastFrameTime);
        self.lastFrameTime = frameTime;
        
        if (frameDuration > 0.0)
        {
            self.angle = CGPointMake(self.angle.x + self.angularVelocity.x * frameDuration, self.angle.y + self.angularVelocity.y * frameDuration);
            self.angularVelocity = CGPointMake(self.angularVelocity.x * (1 - kOSPointCloudViewDamping), self.angularVelocity.y * (1 - kOSPointCloudViewDamping));
        }
    }
    
    private func updateUniforms()
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
        
        self.uniformBuffer = OSPointCloudView.device.newBufferWithBytes(&self.uniforms, length: sizeof(Uniforms), options:MTLResourceOptions.CPUCacheModeDefaultCache);
    }

// MARK: Custom Getter/Setters
    
    func getVertexBuffer() -> MTLBuffer?
    {
        var vertexBuffer : MTLBuffer?;
        dispatch_sync(self.threadSafeConcurrentVertexBufferAccessQueue) { () -> Void in
            vertexBuffer = self.vertexBuffer;
        };
        return vertexBuffer;
    }
    
    func getTransformationBuffer() -> MTLBuffer?
    {
        var transformationBuffer: MTLBuffer?;
        dispatch_sync(self.threadSafeConcurrentTransformationBufferAccessQueue) { () -> Void in
            transformationBuffer = self.transformationBuffer;
        };
        return transformationBuffer;
    }
    
    func setVertexBuffers(vertexBuffer vertexBuffer: MTLBuffer, transformationBuffer: MTLBuffer)
    {
        dispatch_barrier_async(self.threadSafeConcurrentVertexBufferAccessQueue) { () -> Void in
            self.vertexBuffer = vertexBuffer;
            self.transformationBuffer = transformationBuffer;
        };
    }
    
    func getVertexArray() -> [OSPoint]?
    {
        var vertexArray: [OSPoint]?
        dispatch_sync(self.threadSafeConcurrentVertexAccessQueue) { () -> Void in
            vertexArray = self.vertices;
        }
        return vertexArray;
    }

    func setVertexArray(vertexArray: [OSPoint])
    {
        dispatch_barrier_async(self.threadSafeConcurrentVertexAccessQueue) { () -> Void in
            self.vertices = vertexArray;
        };
    }
    
// MARK: Publics
    
    func appendFrame(frame: OSBaseFrame)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
            self.transformationMatrices.append(frame.transformationMatrix);
            let transformationBuffer = OSPointCloudView.device.newBufferWithBytes(self.transformationMatrices, length: self.transformationMatrices.count * sizeof(Matrix4), options: []);
            
//            self.setVertexArray(self.vertices + frame.pointCloud);
            self.vertices += frame.pointCloud;
            
            let vertexBuffer = OSPointCloudView.device.newBufferWithBytes(self.getVertexArray()!, length: self.getVertexArray()!.count * sizeof(OSPoint), options: []);
            self.setVertexBuffers(vertexBuffer: vertexBuffer, transformationBuffer: transformationBuffer);
        };
        self.isReadForAction = true;

    }
    
// MARK: Gesture Recogniser
    func gestureRecognizerDidRecognize(recogniser : UIPanGestureRecognizer)
    {
        let velocity: CGPoint = recogniser.velocityInView(self);
        self.angularVelocity = CGPointMake(velocity.x * kOSPointCloudViewVelocityScale, velocity.y * kOSPointCloudViewVelocityScale);
    }
    
// MARK: OSContentLoadingProtocol
    
    static func loadContent(completionHandler: (() -> Void)!)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
            OSPointCloudView.device;
            
            OSPointCloudView.commandQueue;
            
            if (OSPointCloudView.pipelineState == nil)
            {
                let defaultLibrary = OSPointCloudView.device.newDefaultLibrary();
                let vertexFunction = defaultLibrary!.newFunctionWithName("pointCloudVertex");
                let fragmentFunction = defaultLibrary!.newFunctionWithName("pointCloudFragment");
                
                let pipelineStateDescriptor = MTLRenderPipelineDescriptor();
                pipelineStateDescriptor.vertexFunction = vertexFunction;
                pipelineStateDescriptor.fragmentFunction = fragmentFunction;
                pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm;
                
                do{
                    OSPointCloudView.pipelineState = try OSPointCloudView.device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor);
                } catch _ {
                    OSPointCloudView.pipelineState = nil;
                    print("Failed to create pipeline state.");
                    
                };
                
                
                let depthStencilDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor();
                depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.Less;
                
                depthStencilDescriptor.depthWriteEnabled = true;
                
                OSPointCloudView.depthStencilState = OSPointCloudView.device.newDepthStencilStateWithDescriptor(depthStencilDescriptor);

            }
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                completionHandler?();
            };
        };
    }
}
