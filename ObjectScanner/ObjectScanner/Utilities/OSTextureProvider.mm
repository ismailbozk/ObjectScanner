//
//  OSTextureProvider.m
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
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
