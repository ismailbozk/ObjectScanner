//
//  OSBaseFrame.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSBaseFrame.h"

@implementation OSBaseFrame

- (instancetype)initWithImage:(UIImage *)image depth:(float *)depth
{
    self = [super init];
    if (self) {
        _image = image;
        _depth = depth;
    }
    return self;
}


@end
