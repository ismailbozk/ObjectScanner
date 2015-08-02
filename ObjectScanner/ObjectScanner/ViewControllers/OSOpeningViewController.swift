//
//  OSOpeningViewController.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit

class OSOpeningViewController: OSViewController, OSScannerManagerDelegate {
    
// MARK: Variables
    @IBOutlet weak var startScanningButton: UIButton!
    
    @IBOutlet weak var pointCloudView: OSPointCloudView!
// MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        OSScannerManager.sharedInstance.delegate = self;
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
    
// MARK: OSScannerManagerDelegate
    
    func scannerManagerDidPreparedFrame(scannerManager: OSScannerManager, frame: OSBaseFrame)
    {
        self.pointCloudView.setVertices(frame.pointCloud);
    }
}
