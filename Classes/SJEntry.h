//
//  SJEntry.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJEntry : NSObject<NSCoding>

@property (nonatomic, copy, readonly) NSString *pk;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *thumbnailPath;
@property (nonatomic, strong) NSDate *date;

+ (instancetype)newInstance;

- (BOOL)validate;

@end
