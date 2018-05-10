//
//  SJThumbnailGenerator.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJThumbnailGenerator.h"

#import <AVFoundation/AVFoundation.h>
#import "UIImage+Resize.h"
#import "SJCache.h"

@implementation SJThumbnailGenerator

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    });
    return queue;
}

+ (NSOperation *)generateThumbnailOfSize:(NSInteger)size
                          forVideoAtPath:(NSString *)path
                              completion:(void (^)(UIImage *))completion {
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@-thumbnail-%dx%d", path, size, size];
    [[SJCache sharedCache] objectForKey:cacheKey completion:^(UIImage *cachedImage) {
        if (cachedImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(cachedImage);
            });
            
        } else {
            [operation addExecutionBlock:^{
                NSURL *assetURL = [[NSURL alloc] initFileURLWithPath:path];
                AVAsset *asset = [AVAsset assetWithURL:assetURL];
                AVAssetImageGenerator *generator =
                [[AVAssetImageGenerator alloc] initWithAsset:asset];
                NSArray *times = @[[NSValue valueWithCMTime:kCMTimeZero]];
                [generator generateCGImagesAsynchronouslyForTimes:times completionHandler:
                 ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                     UIImage *thumbnail;
                     if (result == AVAssetImageGeneratorSucceeded) {
                         thumbnail = [UIImage imageWithCGImage:image scale:1.0 orientation:UIImageOrientationRight];
                         thumbnail = [thumbnail squareThumbnailImageOfSize:size];
                         [[SJCache sharedCache] setObject:thumbnail forKey:cacheKey];
                     }
                     dispatch_async(dispatch_get_main_queue(), ^{
                         completion(thumbnail);
                     });
                 }];
            }];
            [self.queue addOperation:operation];
        }
    }];
    
    return operation;
}

@end
