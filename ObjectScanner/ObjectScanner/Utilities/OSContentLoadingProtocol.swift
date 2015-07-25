//
//  ContentLoadingProtocol.swift
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 25/07/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

import Foundation

protocol OSContentLoadingProtocol : class
{
    static func loadContent(completionHandler : (() -> Void)!);
}