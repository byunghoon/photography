//
//  TryCatch.m
//  Photography
//
//  Created by Byunghoon Yoon on 2015-09-07.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

#import "ObjcUtility.h"

@implementation ObjcUtility

+ (void)tryBlock:(void (^)())tryBlock catchBlock:(void (^)(NSException *))catchBlock finallyBlock:(void (^)())finallyBlock {
    @try {
        tryBlock ? tryBlock() : nil;
    }
    @catch (NSException *e) {
        catchBlock ? catchBlock(e) : nil;
    }
    @finally {
        finallyBlock ? finallyBlock() : nil;
    }
}

@end