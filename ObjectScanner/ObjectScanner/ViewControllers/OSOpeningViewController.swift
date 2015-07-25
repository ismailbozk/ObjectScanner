//
//  OSOpeningViewController.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit

class OSOpeningViewController: OSViewController {
    
// MARK: Variables
    @IBOutlet weak var imageView: UIImageView!
    
// MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        if (OSScannerManager.sharedInstance.state == OSScannerManagerState.ContentLoading)
        {
            self.startLoading();
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("scannerManagerDidStartLoadingContent"), name: OSScannerManagerState.ContentLoading.rawValue, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("scannerManagerStatusDidLoadContent"), name: OSScannerManagerState.ContentLoaded.rawValue, object: nil);
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated);
        NSNotificationCenter.defaultCenter().removeObserver(self, name: OSScannerManagerState.ContentLoading.rawValue, object: nil);
        NSNotificationCenter.defaultCenter().removeObserver(self, name: OSScannerManagerState.ContentLoaded.rawValue, object: nil);
    }
    
// MARK: OSScannerManager Utilities
    func scannerManagerDidStartLoadingContent()
    {
        self.startLoading();
    }
    
    func scannerManagerStatusDidLoadContent()
    {
        self.stopLoading();
    }
}
