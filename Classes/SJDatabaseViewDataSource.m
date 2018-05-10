//
//  SJEntriesDataSource.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJDatabaseViewDataSource.h"

#import "SJDatabaseController.h"

@interface SJDatabaseViewDataSource ()

@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseConnection *connection;

@end


@implementation SJDatabaseViewDataSource

#pragma mark -
#pragma mark NSObject

- (id)initWithMappings:(YapDatabaseViewMappings *)viewMappings
              database:(YapDatabase *)database {
    
    if (self = [super init]) {
        self.mappings = viewMappings;
        
        self.connection = database.newConnection;
        [self.connection beginLongLivedReadTransaction];
        [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.mappings updateWithTransaction:transaction];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:database];
    }
    return self;
}


#pragma mark -
#pragma mark Public

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [self.mappings numberOfItemsInSection:section];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    __block id item;
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:self.mappings.view];
        item = [viewTransaction objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    return item;
}


#pragma mark -
#pragma mark Notification Listeners

- (void)onDatabaseModified:(NSNotification *)notification {
    NSArray *notifications = [self.connection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    YapDatabaseViewConnection *viewConnection = [self.connection ext:self.mappings.view];
    [viewConnection getSectionChanges:&sectionChanges
                           rowChanges:&rowChanges
                     forNotifications:notifications
                         withMappings:self.mappings];
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0) {
        return;
    }
    
    NSMutableIndexSet *insertedSections = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *deletedSections = [[NSMutableIndexSet alloc] init];
    
    NSMutableArray *insertedItems = [[NSMutableArray alloc] init];
    NSMutableArray *deletedItems = [[NSMutableArray alloc] init];
    NSMutableArray *changedItems = [[NSMutableArray alloc] init];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges) {
        switch (sectionChange.type) {
            case YapDatabaseViewChangeDelete: {
                [deletedSections addIndex:sectionChange.index];
                break;
            }
            case YapDatabaseViewChangeInsert: {
                [insertedSections addIndex:sectionChange.index];
                break;
            }
            case YapDatabaseViewChangeMove:
            case YapDatabaseViewChangeUpdate: {
                break;
            }
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges) {
        switch (rowChange.type) {
            case YapDatabaseViewChangeDelete: {
                [deletedItems addObject:rowChange.indexPath];
                break;
            }
            case YapDatabaseViewChangeInsert: {
                [insertedItems addObject:rowChange.newIndexPath];
                break;
            }
            case YapDatabaseViewChangeMove: {
                [deletedItems addObject:rowChange.indexPath];
                [insertedItems addObject:rowChange.newIndexPath];
                break;
            }
            case YapDatabaseViewChangeUpdate: {
                [changedItems addObject:rowChange.indexPath];
                break;
            }
        }
    }
    
    [self.connection beginLongLivedReadTransaction];
    
    [self.delegate dataSourceDidChange:self
                      insertedSections:insertedSections
                       deletedSections:deletedSections
                         insertedItems:insertedItems
                          deletedItems:deletedItems
                          changedItems:changedItems];
}

@end
