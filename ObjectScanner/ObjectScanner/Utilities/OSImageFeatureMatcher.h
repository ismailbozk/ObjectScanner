//
//  OSImageFeatureMatcher.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 09/08/2015.
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

#import <Foundation/Foundation.h>

typedef struct
{
    CGPoint trainPoint;
    CGPoint queryPoint;
}OSMatch;

@interface OSImageFeatureMatcher : NSObject

+ (nonnull instancetype)sharedInstance;

/**
 @abstract this method will matched consecutive frames. Call this method again and again to process consecutive frame matching.
 @param image the query image. That image will be converted to gray image and the SURF features will be extracted from it. After the match process is completed, the image features will be the next train features, for the next match operation.
 @note first call of this method will return nil. Because there will be no train feature to match.
 return OSMatch array
 */
- (nullable NSMutableArray *)matchImage:(nonnull UIImage *)image;

@end
