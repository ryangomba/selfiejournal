//
//  SJCache.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJCache.h"

@implementation SJCache

+ (instancetype)sharedCache {
    static SJCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[SJCache alloc] initWithName:@"cache"
                                 diskCapacity:100 * 1024 * 1024
                               maxObjectCount:1000];
    });
    return cache;
}

@end
