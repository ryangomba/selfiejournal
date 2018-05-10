//
//  SJEntry.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJEntry.h"

@interface SJEntry ()

@property (nonatomic, copy, readwrite) NSString *pk;

@end

@implementation SJEntry

+ (instancetype)newInstance {
    SJEntry *entry = [[self alloc] init];
    entry.pk = [[NSUUID UUID] UUIDString];
    return entry;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.pk = [aDecoder decodeObjectForKey:@"pk"];
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pk forKey:@"pk"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
}

- (BOOL)validate {
    if (!self.pk) {
        NSAssert(NO, @"Missing PK");
        return NO;
    }
    if (!self.text) {
        NSAssert(NO, @"Missing text");
        return NO;
    }
    if (!self.date) {
        NSAssert(NO, @"Missing date");
        return NO;
    }
    if (!self.filePath) {
        NSAssert(NO, @"Missing file path");
        return NO;
    }
    return YES;
}

@end
