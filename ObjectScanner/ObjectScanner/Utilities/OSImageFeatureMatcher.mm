//
//  OSImageFeatureMatcher.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 09/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSImageFeatureMatcher.h"

#ifdef __cplusplus

#import "map"


#import <opencv2/core/core.hpp>
#import "opencv2/features2d/features2d.hpp"
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#import <opencv2/legacy/legacy.hpp>

//#include "opencv2/xfeatures2d.hpp"
//#include <opencv2/nonfree/nonfree.hpp>

#endif

static short surfHessianThreshold = 300;
static float uniquenessThreshold = 0.8f;
static short k = 2;
static float ransacThreshold = 0.2f;

static OSImageFeatureMatcher *sharedInstance;

@interface OSImageFeatureMatcher()
{
    cv::SurfFeatureDetector _detector;
    cv::SurfDescriptorExtractor _extractor;
    cv::BFMatcher _matcher;
    
    std::map<NSUInteger, std::shared_ptr<std::vector<cv::KeyPoint>>> _descriptors;
    std::map<NSUInteger, std::shared_ptr<std::vector<cv::Mat>>> _keyPoints;
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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _descriptors = std::map<NSUInteger, std::shared_ptr<std::vector<cv::KeyPoint>>>();
        _keyPoints = std::map<NSUInteger, std::shared_ptr<std::vector<cv::Mat>>>();
        _matcher = cv::BFMatcher();
    }
    return self;
}

- (void)seedWithImage:(UIImage *)image
{

}

@end
