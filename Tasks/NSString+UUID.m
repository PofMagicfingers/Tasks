//
//  NSString+UUID.m
//  Tasks
//
//  Created by Pof on 01/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//
#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString *)UUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);

    return uuidStr;
}

@end