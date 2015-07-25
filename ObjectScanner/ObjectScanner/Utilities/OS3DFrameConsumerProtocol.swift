//
//  OS3DFrameProviderProtocol.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 19/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

import Foundation
import UIKit

protocol OS3DFrameConsumerProtocol:class
{
    func didCapturedFrame(image : UIImage, depthFrame: [Float]);
}