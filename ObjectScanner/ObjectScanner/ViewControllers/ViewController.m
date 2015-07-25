//
//  ViewController.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, assign) NSUInteger loadingProgressCounter;
@property (nonatomic, strong) UIView *loadingView;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _loadingProgressCounter = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _loadingProgressCounter = 0;
    }
    return self;
}

- (UIView *)loadingView
{
    if (!_loadingView)
    {
        _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
        _loadingView.backgroundColor = [UIColor colorWithWhite:0. alpha:0.8];
        [_loadingView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|
                                           UIViewAutoresizingFlexibleWidth|
                                           UIViewAutoresizingFlexibleBottomMargin|
                                           UIViewAutoresizingFlexibleTopMargin|
                                           UIViewAutoresizingFlexibleLeftMargin|
                                           UIViewAutoresizingFlexibleRightMargin)];
    }
    return _loadingView;
}

#pragma mark - Publics
- (void)startLoading
{
    if (self.loadingProgressCounter == 0)
    {
        [UIView animateWithDuration:.3f animations:^{
            [self.view addSubview:self.loadingView];
            self.loadingView.alpha = 1.f;
        }];
    }
    self.loadingProgressCounter++;
}

- (void)stopLoading
{
    if (self.loadingProgressCounter == 0)
    {
        //do nothing
        return;
    }
    else if (self.loadingProgressCounter == 1)
    {
        self.loadingView.alpha = .0f;
        [self.loadingView removeFromSuperview];
    }
    self.loadingProgressCounter--;
}

@end
