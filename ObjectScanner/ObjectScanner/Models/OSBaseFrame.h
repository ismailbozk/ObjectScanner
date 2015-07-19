//
//  OSBaseFrame.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

struct OSBaseFramePoint {
    float x;
    float y;
    float z;
    float r;
    float g;
    float b;
};

@interface OSBaseFrame : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong, readonly) UIImage *grayImage;
@property (nonatomic, assign) float *depth;

- (instancetype)initWithImage:(UIImage *)image depth:(float *)depth;

@end
