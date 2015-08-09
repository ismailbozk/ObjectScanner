//
//  OSScannerManager.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 25/07/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

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
        // calibrating the frame
        dispatch_semaphore_wait(self.calibrationSemaphore, DISPATCH_TIME_FOREVER);
        OSTimer.tic();
        frame.preparePointCloud {[unowned self] () -> Void in
            OSTimer.toc("frame calibrated and converted into 3D space");
            dispatch_semaphore_signal(self.calibrationSemaphore);
            self.appendFrame(frame);
            
            self.delegate?.scannerManagerDidPreparedFrame(self, frame: frame);
        };
        
        // image feature extracting
        dispatch_semaphore_wait(self.featureExtractionSemaphore, DISPATCH_TIME_FOREVER)
        
        dispatch_semaphore_signal(self.featureExtractionSemaphore);
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
