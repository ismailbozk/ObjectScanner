//
//  OSOpeningViewController.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
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
        self.startScanningButton.enabled = false;
    }
    
// MARK: OSScannerManager Utilities

    func scannerManagerStatusDidLoadContent()
    {
        self.stopLoading();
    }
    
// MARK: OSScannerManagerDelegate
    
    func scannerManagerDidPreparedFrame(scannerManager: OSScannerManager, frame: OSBaseFrame)
    {
        self.pointCloudView.appendFrame(frame);
    }
}
