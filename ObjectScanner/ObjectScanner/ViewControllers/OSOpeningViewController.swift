//
//  OSOpeningViewController.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit

class OSOpeningViewController: OSViewController , OS3DFrameProviderProtocol {
    
// MARK: Variables
    @IBOutlet weak var imageView: UIImageView!
    
// MARK: Lifecycle
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        OSCameraFrameProviderSwift.sharedInstance.delegate = self;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        var c = OSBaseFrame();
        c.unitTest();
        
//        self.startLoading();
//        var frameProvider : OSCameraFrameProviderSwift = OSCameraFrameProviderSwift.sharedInstance;
//        frameProvider.prepareFramesWithCompletion({ () -> Void in
//            self.stopLoading();
//            self.imageView.image = frameProvider.images[0] as? UIImage;
//            frameProvider.startSimulatingFrameCaptures();
//        });
    }
    
    
// MARK: OS3DFrameProviderProtocol
    
    func didCapturedFrame(image: UIImage, depthFrame: [Float]) {
        
    }
}
