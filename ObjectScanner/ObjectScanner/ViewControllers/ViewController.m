//
//  ViewController.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
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
