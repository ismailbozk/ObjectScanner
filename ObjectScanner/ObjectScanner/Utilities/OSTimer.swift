//
//  OSTimer.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 22/07/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

import UIKit
private var lastTicTime : CFTimeInterval = 0.0;
class OSTimer: NSObject {
    class func tic()
    {
        lastTicTime = CACurrentMediaTime();
    }
    
    class func toc(tag : String)
    {
        print("\(CACurrentMediaTime() - lastTicTime) seconds. Task: \(tag)");
    }
}
