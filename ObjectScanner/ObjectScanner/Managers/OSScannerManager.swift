//
//  OSScannerManager.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 25/07/2015.
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

import simd

private let kOSScannerManagerMinNumberOfMatchesForRegistrationProcess = 3;

enum OSScannerManagerState: String
{
    case Idle = "OSScannerManagerIdle"
    case ContentLoading = "OSScannerManagerDidStartContentLoading"
    case ContentLoaded = "OSScannerManagerDidStartContentLoaded"
    case Scanning = "OSScannerManagerScaning"
    case ScanCompleted = "OSScannerManagerScanCompleted"
}

protocol OSScannerManagerDelegate : class
{
    func scannerManagerDidPreparedFrame(scannerManager: OSScannerManager, frame: OSBaseFrame) -> Void;
}

class OSScannerManager : OS3DFrameConsumerProtocol
{
// MARK: Properties
    weak var delegate : OSScannerManagerDelegate?;
    var state : OSScannerManagerState = .Idle {
        didSet
        {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(self.state.rawValue, object:self);
            };
        }
    };
    
    private let calibrationSemaphore : dispatch_semaphore_t = dispatch_semaphore_create(1);
    private let featureExtractionSemaphore : dispatch_semaphore_t = dispatch_semaphore_create(1);
    private let threadSafeConcurrentFrameArrayConcurrentQueue : dispatch_queue_t = dispatch_queue_create("OSScannerManagerThreadSafeConcurrentFrameArrayConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);//don't use that queue anywhere else other than custom getters and setters for consecutiveFrames property.
    private var consecutiveFrames : [OSBaseFrame] = [OSBaseFrame]();
    
    private var isThisTheFirstTime = true;

// MARK: Custom concurrentFrameArray Getter/Setters
    
    private func frameAtIndex(index : Int) -> OSBaseFrame
    {
        var frame : OSBaseFrame!
        
        dispatch_sync(self.threadSafeConcurrentFrameArrayConcurrentQueue) { () -> Void in
            frame = self.consecutiveFrames[index];
        };
        
        return frame;
    }
    
    private func removeFrame(index : Int)
    {
        dispatch_barrier_async(self.threadSafeConcurrentFrameArrayConcurrentQueue) { () -> Void in
            self.consecutiveFrames.removeAtIndex(index);
        };
    }
    
    private func appendFrame(frame : OSBaseFrame)
    {
        dispatch_barrier_async(self.threadSafeConcurrentFrameArrayConcurrentQueue) { () -> Void in
            self.consecutiveFrames.append(frame);
        };
    }
    
// MARK: Lifecycle
    
    static let sharedInstance = OSScannerManager();

    init()
    {
        OSCameraFrameProviderSwift.sharedInstance.delegate = self;
        self.startLoadingContent();
    }
    
// MARK: Publics
    
    func startSimulating()
    {
        switch (self.state)
        {
        case .Idle, .ContentLoading:
            print("warning: content is not loaded, first the content must be loaded.");
            break
        case .ContentLoaded:
            self.state = .Scanning;
            OSCameraFrameProviderSwift.sharedInstance.startSimulatingFrameCaptures();
            break
        case .Scanning:
            print("warning: scanning is in progress.");
            break
        case .ScanCompleted:
            print("warning: scanning is already completed.");
            break
        }
    }
    
// MARK: Utilities
    /**
    @param frame the frame that will be calibrated and put into the scanning process
    @abstract this methd is consist of single frame calibration and image surf feature extractions
    */
    private func startSingleFrameOperations(frame : OSBaseFrame)
    {
        dispatch_semaphore_wait(self.calibrationSemaphore, DISPATCH_TIME_FOREVER);
        self.appendFrame(frame);
        
        // calibrating the frame
        
        frame.preparePointCloud {[unowned self] () -> Void in
            let matchCoordinatesIn2D: NSArray? = OSImageFeatureMatcher.sharedInstance().matchImage(frame.image);
            if (matchCoordinatesIn2D?.count > kOSScannerManagerMinNumberOfMatchesForRegistrationProcess && !self.isThisTheFirstTime)
            {
                let trainFrame = self.frameAtIndex(self.consecutiveFrames.count - 1 - 1);

                var matchesIn3D = NSMutableArray();
                
                var matchIn2D: OSMatch = OSMatch();
                for (var i: Int = 0; i < matchCoordinatesIn2D?.count; i++)
                {
                    let val: NSValue? = matchCoordinatesIn2D?.objectAtIndex(i) as? NSValue;
                    val?.getValue(&matchIn2D);
                    let trainImageIndex = (Int)(matchIn2D.trainPoint.y) * frame.width + (Int)(matchIn2D.trainPoint.x);
                    let queryImageIndex = (Int)(matchIn2D.queryPoint.y) * frame.width + (Int)(matchIn2D.queryPoint.x);
                    if (frame.pointCloud[queryImageIndex].isValid() && trainFrame.pointCloud[trainImageIndex].isValid())
                    {
                        var singleMatch: OSMatch3D = OSMatch3D(queryPoint: frame.pointCloud[queryImageIndex].point, trainPoint: trainFrame.pointCloud[trainImageIndex].point);
                        let singleMatchData: NSData = NSData(bytes: &singleMatch, length: sizeof(OSMatch3D));
                        matchesIn3D.addObject(singleMatchData);
                    }
                }
                
                let transformationMatrixData: NSData = OSRegistrationUtility.createTransformationMatrixWithMatches(matchesIn3D as [AnyObject]);
                var transformationMatrix: Matrix4 = Matrix4.Identity;
                transformationMatrixData.getBytes(&transformationMatrix, length: sizeof(Matrix4));
                
                frame.transformationMatrix = trainFrame.transformationMatrix * transformationMatrix;
                
    

                self.delegate?.scannerManagerDidPreparedFrame(self, frame: frame);
            }
            else if (self.isThisTheFirstTime)
            {
                self.isThisTheFirstTime = false;
                self.delegate?.scannerManagerDidPreparedFrame(self, frame: frame);
            }
            
            dispatch_semaphore_signal(self.calibrationSemaphore);
        };
    }
    
    /**
    @abstract this method will process the consecutive frames
    */
    private func startConsecutiveFrameOperations()
    {
        
    }
    
// MARK: Privates
    
    private func startLoadingContent()
    {
        OSTimer.tic();
        self.state = .ContentLoading;
        let contentLoadingGroup : dispatch_group_t = dispatch_group_create();
        
        dispatch_group_enter(contentLoadingGroup);
        OSCameraFrameProviderSwift.loadContent { () -> Void in
            dispatch_group_leave(contentLoadingGroup);
        };
        
        dispatch_group_enter(contentLoadingGroup);
        OSBaseFrame.loadContent { () -> Void in
            dispatch_group_leave(contentLoadingGroup);
        };
        
        dispatch_group_enter(contentLoadingGroup);
        OSPointCloudView.loadContent { () -> Void in
            dispatch_group_leave(contentLoadingGroup);
        };
        
        dispatch_group_notify(contentLoadingGroup, dispatch_get_main_queue()) { () -> Void in
            OSTimer.toc("content loaded");
            self.state = .ContentLoaded;
        };
    }
    
// MARK: Utilities
    
// MARK: OS3DFrameConsumerProtocol
    func didCapturedFrame(image: UIImage, depthFrame: [Float])
    {
        let capturedFrame : OSBaseFrame = OSBaseFrame(image: image, depth: depthFrame);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { () -> Void in
            self.startSingleFrameOperations(capturedFrame);
        };
    }
}
