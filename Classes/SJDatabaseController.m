//
//  SJDatabase.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJDatabaseController.h"

@implementation SJDatabaseController

#pragma mark -
#pragma mark Database

+ (YapDatabase *)database {
    static YapDatabase *database;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databasePath = [applicationSupportDirectory stringByAppendingString:@"database.sqlite"];
        database = [[YapDatabase alloc] initWithPath:databasePath];
    });
    return database;
}


#pragma mark -
#pragma mark Dependents

+ (NSMutableDictionary *)viewDependentsMap {
    static NSMutableDictionary *viewDependentsMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        viewDependentsMap = [[NSMutableDictionary alloc] init];
    });
    return viewDependentsMap;
}

+ (void)addDependent:(id)dependent
        forExtension:(YapDatabaseExtension *)extension
       extensionName:(NSString *)extensionName {
    
    NSAssert([NSThread isMainThread], @"Expected main thread");
    
    NSHashTable *dependents = [self.viewDependentsMap objectForKey:extensionName];
    if (!dependents) {
        dependents = [NSHashTable weakObjectsHashTable];
        [self.viewDependentsMap setObject:dependents forKey:extensionName];
    }
    
    [dependents addObject:dependent];
    
    if (dependents.count > 0) {
        [self.database registerExtension:extension withName:extensionName];
    }
}

+ (void)removeDependent:(id)dependent
      forExtensionNamed:(NSString *)extensionName {
    
    NSAssert([NSThread isMainThread], @"Expected main thread");
    
    NSHashTable *dependents = [self.viewDependentsMap objectForKey:extensionName];
    
    [dependents removeObject:dependent];
    
    if (dependents.count == 0) {
        [self.database unregisterExtension:extensionName];
    }
}


#pragma mark -
#pragma mark Debug

+ (void)flushDatabase {
    [self.database.newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInAllCollections];
    }];
}

@end
