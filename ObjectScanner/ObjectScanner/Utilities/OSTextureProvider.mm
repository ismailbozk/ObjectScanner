//
//  OSTextureProvider.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import "OSTextureProvider.h"

@implementation OSTextureProvider

+ (id<MTLTexture>)textureWithImage:(UIImage *)image device:(id<MTLDevice>)device
{
    UIImage *pImage = image;
    
    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t width  = uint32_t(CGImageGetWidth(pImage.CGImage));
    uint32_t height = uint32_t(CGImageGetHeight(pImage.CGImage));

    uint32_t rowBytes = width * 4;
    
    CGContextRef pContext = CGBitmapContextCreate(NULL,
                                                  width,
                                                  height,
                                                  8,
                                                  rowBytes,
                                                  pColorSpace,
                                                  CGBitmapInfo(kCGImageAlphaPremultipliedLast));
    
    CGColorSpaceRelease(pColorSpace);
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, width, height);
    
    CGContextClearRect(pContext, bounds);
    
    CGContextDrawImage(pContext, bounds, pImage.CGImage);
    
    MTLTextureDescriptor *pTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                        width:width
                                                                                       height:height
                                                                                    mipmapped:NO];
    
    id<MTLTexture> texture = [device newTextureWithDescriptor:pTexDesc];
    
    if(!texture)
    {
        CGContextRelease(pContext);
    }
    
    const void *pPixels = CGBitmapContextGetData(pContext);
    
    if(pPixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        
        [texture replaceRegion:region
                   mipmapLevel:0
                     withBytes:pPixels
                   bytesPerRow:rowBytes];
    } // if
    
    CGContextRelease(pContext);
    
    return texture;
}

@end
