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
    func scannerManagerDidPreparedFrame(_ scannerManager: OSScannerManager, frame: OSBaseFrame) -> Void;
}

class OSScannerManager : OS3DFrameConsumerProtocol
{
// MARK: Properties
    weak var delegate : OSScannerManagerDelegate?;
    var state : OSScannerManagerState = .Idle {
        didSet
        {
            DispatchQueue.main.async { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: self.state.rawValue), object:self);
            };
        }
    };
    
    fileprivate let calibrationSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1);
    fileprivate let featureExtractionSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1);
    fileprivate let threadSafeConcurrentFrameArrayConcurrentQueue : DispatchQueue = DispatchQueue(label: "OSScannerManagerThreadSafeConcurrentFrameArrayConcurrentQueue", attributes: DispatchQueue.Attributes.concurrent);//don't use that queue anywhere else other than custom getters and setters for consecutiveFrames property.
    fileprivate var consecutiveFrames : [OSBaseFrame] = [OSBaseFrame]();
    
    fileprivate var isThisTheFirstTime = true;

// MARK: Custom concurrentFrameArray Getter/Setters
    
    fileprivate func frameAtIndex(_ index : Int) -> OSBaseFrame
    {
        var frame : OSBaseFrame!
        
        self.threadSafeConcurrentFrameArrayConcurrentQueue.sync { () -> Void in
            frame = self.consecutiveFrames[index];
        };
        
        return frame;
    }
    
    fileprivate func removeFrame(_ index : Int)
    {
        self.threadSafeConcurrentFrameArrayConcurrentQueue.async(flags: .barrier, execute: { () -> Void in
            self.consecutiveFrames.remove(at: index);
        }) ;
    }
    
    fileprivate func appendFrame(_ frame : OSBaseFrame)
    {
        self.threadSafeConcurrentFrameArrayConcurrentQueue.async(flags: .barrier, execute: { () -> Void in
            self.consecutiveFrames.append(frame);
        }) ;
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
    fileprivate func startSingleFrameOperations(_ frame : OSBaseFrame)
    {
        self.calibrationSemaphore.wait(timeout: DispatchTime.distantFuture);
        self.appendFrame(frame);
        
        // calibrating the frame
        
        frame.preparePointCloud {[unowned self] () -> Void in
            let matchCoordinatesIn2D: NSArray? = OSImageFeatureMatcher.sharedInstance().match(frame.image);
            if let matchCoordinatesIn2D = matchCoordinatesIn2D,
                (matchCoordinatesIn2D.count > kOSScannerManagerMinNumberOfMatchesForRegistrationProcess && !self.isThisTheFirstTime)
            {
                let trainFrame = self.frameAtIndex(self.consecutiveFrames.count - 1 - 1);

                var matchesIn3D = NSMutableArray();
                
                var matchIn2D: OSMatch = OSMatch();
                let count = matchCoordinatesIn2D.count
                for i: Int in 0..<count
                {
                    let val: NSValue? = matchCoordinatesIn2D.object(at: i) as? NSValue;
                    val?.getValue(&matchIn2D);
                    let trainImageIndex = (Int)(matchIn2D.trainPoint.y) * frame.width + (Int)(matchIn2D.trainPoint.x);
                    let queryImageIndex = (Int)(matchIn2D.queryPoint.y) * frame.width + (Int)(matchIn2D.queryPoint.x);
                    if (frame.pointCloud[queryImageIndex].isValid() && trainFrame.pointCloud[trainImageIndex].isValid())
                    {
                        var singleMatch: OSMatch3D = OSMatch3D(queryPoint: frame.pointCloud[queryImageIndex].point, trainPoint: trainFrame.pointCloud[trainImageIndex].point);
                        let singleMatchData: Data = Data(bytes: &singleMatch, count: MemoryLayout<OSMatch3D>.size);
                        matchesIn3D.add(singleMatchData);
                    }
                }
                
                let transformationMatrixData: Data = OSRegistrationUtility.createTransformationMatrix(withMatches: matchesIn3D as [AnyObject]);
                var transformationMatrix: Matrix4 = Matrix4.Identity;
                (transformationMatrixData as NSData).getBytes(&transformationMatrix, length: MemoryLayout<Matrix4>.size);
                
                frame.transformationMatrix = trainFrame.transformationMatrix * transformationMatrix;
                
    

                self.delegate?.scannerManagerDidPreparedFrame(self, frame: frame);
            }
            else if (self.isThisTheFirstTime)
            {
                self.isThisTheFirstTime = false;
                self.delegate?.scannerManagerDidPreparedFrame(self, frame: frame);
            }
            
            self.calibrationSemaphore.signal();
        };
    }
    
    /**
    @abstract this method will process the consecutive frames
    */
    fileprivate func startConsecutiveFrameOperations()
    {
        
    }
    
// MARK: Privates
    
    fileprivate func startLoadingContent()
    {
        OSTimer.tic();
        self.state = .ContentLoading;
        let contentLoadingGroup : DispatchGroup = DispatchGroup();
        
        contentLoadingGroup.enter();
        OSCameraFrameProviderSwift.loadContent { () -> Void in
            contentLoadingGroup.leave();
        };
        
        contentLoadingGroup.enter();
        OSBaseFrame.loadContent { () -> Void in
            contentLoadingGroup.leave();
        };
        
        contentLoadingGroup.enter();
        OSPointCloudView.loadContent { () -> Void in
            contentLoadingGroup.leave();
        };
        
        contentLoadingGroup.notify(queue: DispatchQueue.main) { () -> Void in
            OSTimer.toc("content loaded");
            self.state = .ContentLoaded;
        };
    }
    
// MARK: Utilities
    
// MARK: OS3DFrameConsumerProtocol
    func didCapturedFrame(_ image: UIImage, depthFrame: [Float])
    {
        let capturedFrame : OSBaseFrame = OSBaseFrame(image: image, depth: depthFrame);
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { () -> Void in
            self.startSingleFrameOperations(capturedFrame);
        };
    }
}
