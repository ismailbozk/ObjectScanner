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
}

class OSScannerManager : OS3DFrameConsumerProtocol
{
// MARK: Properties
    var state : OSScannerManagerState = .Idle {
        didSet
        {
            NSNotificationCenter.defaultCenter().postNotificationName(self.state.rawValue, object:self);
        }
    };
    
// MARK: Lifecycle
    static let sharedInstance = OSScannerManager();

    init()
    {
        OSCameraFrameProviderSwift.sharedInstance.delegate = self;
        self.startLoadingContent();
    }
    
    
    
// MARK: Utilities
// MARK: Publics
    
    func startLoadingContent()
    {
        OSTimer.tic();
        self.state = .ContentLoading;
        print("OSScannerManager ")
        let contentLoadingGroup : dispatch_group_t = dispatch_group_create();
        
        dispatch_group_enter(contentLoadingGroup);
        OSCameraFrameProviderSwift.loadContent { () -> Void in
            dispatch_group_leave(contentLoadingGroup);
        };
        
        dispatch_group_enter(contentLoadingGroup);
        OSBaseFrame.loadContent { () -> Void in
            dispatch_group_leave(contentLoadingGroup);
        };
        
        dispatch_group_notify(contentLoadingGroup, dispatch_get_main_queue()) { () -> Void in
            OSTimer.toc("content loaded");
            self.state = .ContentLoaded;
        };
    }
    
// MARK: Utilities
// MARK: Utilities
// MARK: Utilities
    
// MARK: OS3DFrameConsumerProtocol
    func didCapturedFrame(image: UIImage, depthFrame: [Float])
    {
        
    }
}
