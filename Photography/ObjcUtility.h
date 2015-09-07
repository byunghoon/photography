//
//  ObjcUtility.h
//  Photography
//
//  Created by Byunghoon Yoon on 2015-09-07.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjcUtility : NSObject

+ (void)tryBlock:(void (^)())tryBlock catchBlock:(void (^)(NSException *))catchBlock finallyBlock:(void (^)())finallyBlock;

@end
