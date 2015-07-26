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
    @IBOutlet weak var startScanningButton: UIButton!
    
// MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        OSScannerManager.sharedInstance;    //this will trigger content loading
        self.startLoading();
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("scannerManagerStatusDidLoadContent"), name: OSScannerManagerState.ContentLoaded.rawValue, object: nil);
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated);
        NSNotificationCenter.defaultCenter().removeObserver(self, name: OSScannerManagerState.ContentLoaded.rawValue, object: nil);
    }
    
// MARK: Actions
    @IBAction func startScanning(sender: AnyObject)
    {
        OSScannerManager.sharedInstance.startSimulating();
    }
    
// MARK: OSScannerManager Utilities

    func scannerManagerStatusDidLoadContent()
    {
        self.stopLoading();
    }
}
