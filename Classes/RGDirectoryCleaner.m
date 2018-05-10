// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "RGDirectoryCleaner.h"

#import "RGTiming.h"
#import "RGMacros.h"

@implementation RGDirectoryCleaner

+ (void)startBackgroundTrashCleanupTask {
    [self performFolderCleanup:@[[self trashPath]] removeRootFolder:NO];
}

+ (NSString *)trashPathForPath:(NSString *)path {
    NSString *uniqueSubPath = [NSString stringWithFormat:@"%@-%@", [path lastPathComponent], [[NSUUID UUID] UUIDString]];
    NSString *trashSubdirectoryPath = [[self trashPath] stringByAppendingPathComponent:uniqueSubPath];
    return trashSubdirectoryPath;
}

+ (NSString *)trashPath {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"rg-recycle-bin"];

    // use synchronized to avoid two threads creating the directory at the same time
    @synchronized(self) {
        // passing yes to withIntermediateDirectories will return YES if it already exists
        NSError *error = NULL;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSAssert(NO, [error description]);
        }
    }

    return path;
}

+ (BOOL)trashItemAtPath:(NSString *)path error:(NSError **)error {
    NSError *moveError = nil;
    NSString *trashPath = [self trashPathForPath:path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager moveItemAtPath:path toPath:trashPath error:&moveError]) {
        if (moveError.code == NSFileNoSuchFileError) {
            return YES; // the file doesn't exist, so we're successful in removing it
        } else {
            *error = moveError;
            return NO;
        }
    }
    return YES;
}

+ (void)performFolderCleanup:(NSArray *)tempFolderPathCollection removeRootFolder:(BOOL)removeRootFolder {
    static UIBackgroundTaskIdentifier _trimmingTask;
    @synchronized(self) {
        if (_trimmingTask != UIBackgroundTaskInvalid) {
            return;
        }
        _trimmingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        StartTimer();
        on_exit{
            PrintTimeElapsedMessage(@"Finished cleaning trash");
            @synchronized(self) {
                [[UIApplication sharedApplication] endBackgroundTask:_trimmingTask];
                _trimmingTask = UIBackgroundTaskInvalid;
            }
        };

        NSInteger i = 0;

        // create an enumeration object to enumrate all files in this folder
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSString *tempFolderPath in tempFolderPathCollection) {
            // this is a deep enumeration, if you don't believe it check the docs :)
            NSDirectoryEnumerator *fileEnum = [fileManager enumeratorAtPath:tempFolderPath];

            // while enumerating, delete each file and make sure the app does not get killed.
            // let's quit the operation before the app shuts down the task in 5.0 seconds
            NSTimeInterval remainingTimeThreshold = 5.0f;
            BOOL done = NO;

            while ([[UIApplication sharedApplication] backgroundTimeRemaining] >= remainingTimeThreshold) {
                if (i++ % 250 == 0) {
                    // Check if app has become active
                    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                        return;
                    }
                }
                NSString *file = [fileEnum nextObject];

                if (!file) {
                    // no more files, we are done.
                    done = YES;
                    break;
                }

                NSString *filePath = [tempFolderPath stringByAppendingPathComponent:file];
                // only remove files, skip folders
                BOOL isDir;
                [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
                if (!isDir) {
                    [fileManager removeItemAtPath:filePath error:nil];
                    NSLog(@"removed file %@", file);
                }
            }

            // remove the folder itself once we are done
            if (done && removeRootFolder) {
                [fileManager removeItemAtPath:tempFolderPath error:nil];
            }
        }
    });
}

@end
