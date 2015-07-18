//
//  OSOpeningViewController.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSOpeningViewController.h"

#import "OSCameraFrameProvider.h"

@interface OSOpeningViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

@implementation OSOpeningViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self startLoading];
    [[OSCameraFrameProvider sharedInstance] prepareFramesWithCompletion:^{
        UIImage *img = [OSCameraFrameProvider sharedInstance].images[0];
        [self.imgView setImage:img];
        [self stopLoading];        
    }];
}

@end
