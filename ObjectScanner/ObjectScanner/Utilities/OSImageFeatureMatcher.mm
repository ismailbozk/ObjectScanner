//
//  OSImageFeatureMatcher.m
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

#import "OSImageFeatureMatcher.h"

#ifdef __cplusplus

#import "UIImage+OpenCV.h"

#import <opencv2/core/core.hpp>
#import "opencv2/features2d/features2d.hpp"
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#import <opencv2/legacy/legacy.hpp>

#import "Shared.h"

#endif

static short surfHessianThreshold = 100;
static float uniquenessThreshold = 0.9f;
static short k = 2;

static OSImageFeatureMatcher *sharedInstance;

@interface OSImageFeatureMatcher()
{
    cv::SurfFeatureDetector _detector;
    cv::SurfDescriptorExtractor _extractor;
    cv::BFMatcher _matcher;
    
    std::vector<cv::KeyPoint> _trainKeyPoints;   //in other words train or previous frame's
    cv::Mat _trainDescriptors;
}

@end

@implementation OSImageFeatureMatcher

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (nonnull instancetype)init
{
    self = [super init];
    if (self)
    {
        _detector = cv::SurfFeatureDetector(surfHessianThreshold);
        _extractor = cv::SurfDescriptorExtractor();
        _matcher = cv::BFMatcher(cv::NORM_L2, false);
        _trainKeyPoints = std::vector<cv::KeyPoint>();
        _trainDescriptors = cv::Mat();
    }
    return self;
}

- (void)trainWithImage:(UIImage *)image
{
    CFTimeInterval startTime = CACurrentMediaTime();
    
    cv::Mat grayImage = [image cvMatRepresentationGray];
    _detector.detect(grayImage, _trainKeyPoints);
    _extractor.compute(grayImage, _trainKeyPoints, _trainDescriptors);
    
    NSLog(@"Task: TrainImage %f", CACurrentMediaTime() - startTime);
}

- (nullable NSMutableArray *)matchImage:(nonnull UIImage *)image
{
    if (_trainKeyPoints.size() == 0)
    {
        [self trainWithImage:image];
        return nil;
    }
    
    CFTimeInterval startTime = CACurrentMediaTime();
    
    cv::Mat queryDescriptors;
    std::vector<cv::KeyPoint> queryKeyPoints;
    
    cv::Mat testGrayImage = [image cvMatRepresentationGray];
    _detector.detect(testGrayImage, queryKeyPoints);
    _extractor.compute(testGrayImage, queryKeyPoints, queryDescriptors);
    
    std::vector<std::vector<cv::DMatch>> matches;
    cv::Mat maskKnn;
    _matcher.knnMatch(queryDescriptors, _trainDescriptors, matches, k, maskKnn, false);

    std::vector<bool> mask(matches.size(), true);
    VoteForUniqueness(matches, uniquenessThreshold, mask);
    
    
    NSMutableArray *matchPairs = [NSMutableArray new];
    //extract match point on 2D coordinates
    for (int i = 0; i < mask.size(); i++)
    {
        if (mask[i] == true)
        {
            cv::DMatch currentMatch = matches[i][0];
            cv::KeyPoint queryPairKeyPoint = queryKeyPoints[currentMatch.queryIdx];
            cv::KeyPoint trainPairKeyPoint = _trainKeyPoints[currentMatch.trainIdx];
            
            OSMatch match;
            match.trainPoint = CGPointMake(round(trainPairKeyPoint.pt.x), round(trainPairKeyPoint.pt.y));
            match.queryPoint = CGPointMake(round(queryPairKeyPoint.pt.x), round(queryPairKeyPoint.pt.y));

            [matchPairs addObject:[NSValue valueWithBytes:&match objCType:@encode(OSMatch)]];
            //to read use code below
            //OSMatch p;
            //[value getValue:&p];
        }
    }
    
    
    
    //next train features will be current query image features.
    _trainDescriptors = queryDescriptors;
    _trainKeyPoints = queryKeyPoints;
    
    NSLog(@"Task: match images %f", CACurrentMediaTime() - startTime);
    
    return matchPairs;
}

#pragma mark - Utilities

void VoteForUniqueness(std::vector<std::vector<cv::DMatch>>& matches, float threshold, std::vector<bool> &mask)
{
    int currentInliersCount = 0;
    if (mask.size() == matches.size())
    {
        for (int i = 0; i < matches.size(); i++)
        {
            if (matches[i].size() >= 2) //if there is at least two matches
            {
                cv::DMatch firstCand = matches[i][0];
                cv::DMatch secondCand = matches[i][1];
                
                float distRatio = firstCand.distance / secondCand.distance;
                if (distRatio > threshold)
                {
                    mask[i] = false;
                }
                else
                {
                    mask[i] = true;
                    currentInliersCount++;
                }
            }
        }
    }
    else
    {
        NSLog(@"VoteForUniqueness mask and match size must be equal!!!");
    }
}

@end
