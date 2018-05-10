//
//  SJDatabase+Entries.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJDatabaseController+Entries.h"

static NSString * const kEntriesCollectionKey = @"entries";

@implementation SJDatabaseController (Entries)

+ (void)saveEntry:(SJEntry *)entry {
    if (![entry validate]) {
        return;
    }
    [self.database.newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:entry forKey:entry.pk inCollection:kEntriesCollectionKey];
    }];
}

+ (void)deleteEntry:(SJEntry *)entry {
    NSError *deleteError = nil;
    BOOL fileDeletionSuccess =
    [[NSFileManager defaultManager] removeItemAtPath:entry.filePath error:&deleteError];
    NSAssert(fileDeletionSuccess, deleteError.localizedDescription);
    if (fileDeletionSuccess) {
        [self.database.newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction removeObjectForKey:entry.pk inCollection:kEntriesCollectionKey];
        }];
    }
}

+ (YapDatabaseView *)allEntriesView {
    static YapDatabaseView *view;
    if (view) {
        return view;
    }
    
    YapDatabaseViewGroupingWithKeyBlock groupingBlock =
    ^(NSString *collection, NSString *key) {
        return kAllItemsGroup;
    };
    
    YapDatabaseViewSortingWithObjectBlock sortingBlock =
    ^(NSString *group,
      NSString *collection1, NSString *key1, SJEntry *entry1,
      NSString *collection2, NSString *key2, SJEntry *entry2) {
        return [entry1.date compare:entry2.date];
    };
    
    view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                        groupingBlockType:YapDatabaseViewBlockTypeWithKey
                                             sortingBlock:sortingBlock
                                         sortingBlockType:YapDatabaseViewBlockTypeWithObject];
    
    view.options.isPersistent = NO;
    view.options.allowedCollections = [NSSet setWithObject:kEntriesCollectionKey];
    
    return view;
}

@end
