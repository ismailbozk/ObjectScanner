//
//  OSRegistrationUtility.h
//  ObjectScanner
//
//  Created by Ismail Bozkurt on 15/08/2015.
//  Copyright © 2015 Ismail Bozkurt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSRegistrationUtility : NSObject

+ (NSData *)createTransformationMatrixWithMatches:(NSArray *)matches;

@end
