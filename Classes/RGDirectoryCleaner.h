// Copyright 2014-present Ryan Gomba. All rights reserved.

@interface RGDirectoryCleaner : NSObject

+ (void)startBackgroundTrashCleanupTask;

+ (BOOL)trashItemAtPath:(NSString *)path error:(NSError **)error;

@end
