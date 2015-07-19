//
//  OSCameraFrameProvider.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSCameraFrameProvider : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *images;

- (void)prepareFramesWithCompletion:(void(^)())completion;
- (void)startSimulatingFrameCaptures;
@end
