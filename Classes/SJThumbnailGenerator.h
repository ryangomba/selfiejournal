//
//  SJThumbnailGenerator.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJThumbnailGenerator : NSObject

+ (NSOperation *)generateThumbnailOfSize:(NSInteger)size
                          forVideoAtPath:(NSString *)path
                              completion:(void(^)(UIImage *image))completion;

@end
