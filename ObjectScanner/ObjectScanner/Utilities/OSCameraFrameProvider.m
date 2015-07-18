//
//  OSCameraFrameProvider.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 18/07/2015.
//  Copyright (c) 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSCameraFrameProvider.h"

@interface OSCameraFrameProvider()

@property (nonatomic, strong) NSMutableArray *images;

@end

@implementation OSCameraFrameProvider

+ (instancetype)sharedInstance
{
    static OSCameraFrameProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [OSCameraFrameProvider new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _images = [NSMutableArray new];
    }
    return self;
}

- (void)prepareFramesWithCompletion:(void(^)())completion
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        CFTimeInterval startTime = CACurrentMediaTime();

        [self.images addObject:[OSCameraFrameProvider imageForFilePrefix:@"father1"]];
        [self.images addObject:[OSCameraFrameProvider imageForFilePrefix:@"father2"]];
        [self.images addObject:[OSCameraFrameProvider imageForFilePrefix:@"father3"]];
        [self.images addObject:[OSCameraFrameProvider imageForFilePrefix:@"father4"]];
        [self.images addObject:[OSCameraFrameProvider imageForFilePrefix:@"father5"]];
        
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        
        NSLog(@"frames read in %f seconds" ,elapsedTime);
        
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

+ (UIImage *)imageForFilePrefix:(NSString *)filePrefix
{
    int width = 640;
    int height = 480;
    
    NSString *resourceFileName = [NSString stringWithFormat:@"%@RGB", filePrefix];
    NSString *pathToFile = [[NSBundle mainBundle] pathForResource:resourceFileName ofType:@"csv"];
    NSError *error;

    
    NSString *fileString = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:&error];
    if (!fileString) {
        NSLog(@"Error reading file.");
    }
    
    NSArray *channels = [fileString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n;"]];
    
    unsigned c = (unsigned)(width*height * 4);//file only contains r,g and b data alpha is always 1
    uint8_t *bytes = malloc(sizeof(*bytes) * c);//
    
    unsigned i;
    for (i = 0; i < width*height; i++)
    {
        unsigned ind = 4*i;
        unsigned dataInd = 3*i;
        //r
        NSString *str = [channels objectAtIndex:dataInd];
        int byte = [str intValue];
        bytes[ind + 2] = (uint8_t)byte;
        
        //g
        str = [channels objectAtIndex:dataInd+1];
        byte = [str intValue];
        bytes[ind+1] = (uint8_t)byte;
        
        //b
        str = [channels objectAtIndex:dataInd+2];
        byte = [str intValue];
        bytes[ind] = (uint8_t)byte;
        
        //a
        bytes[ind+3] = (uint8_t)255;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, c * 4, NULL);

    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4*width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    /*I get the current dimensions displayed here */
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    return newImage;
}

@end
