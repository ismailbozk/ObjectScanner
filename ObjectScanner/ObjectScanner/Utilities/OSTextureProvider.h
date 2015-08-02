//
//  OSTextureProvider.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 02/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSTextureProvider : NSObject

+ (id<MTLTexture>)textureWithImage:(UIImage *)image device:(id<MTLDevice>)device;

@end
