//
//  OSImageFeatureMatcher.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 09/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct
{
    CGPoint trainPoint;
    CGPoint queryPoint;
}OSMatch;

@interface OSImageFeatureMatcher : NSObject

+ (instancetype)sharedInstance;

/**
 @abstract this method will matched consecutive frames. Call this method again and again to process consecutive frame matching.
 @param image the query image. That image will be converted to gray image and the SURF features will be extracted from it. After the match process is completed, the image features will be the next train features, for the next match operation.
 @note first call of this method will return nil. Because there will be no train feature to match.
 */
- (NSMutableArray *)matchImage:(UIImage *)image;

@end
