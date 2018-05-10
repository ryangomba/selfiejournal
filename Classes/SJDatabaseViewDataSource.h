//
//  SJEntriesDataSource.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YapDatabase;
@class YapDatabaseViewMappings;

@class SJDatabaseViewDataSource;
@protocol SJDatabaseViewDataSourceDelegate <NSObject>

- (void)dataSourceDidChange:(SJDatabaseViewDataSource *)dataSource
           insertedSections:(NSIndexSet *)insertedSections
            deletedSections:(NSIndexSet *)deletedSections
              insertedItems:(NSArray *)insertedItems
               deletedItems:(NSArray *)deletedItems
               changedItems:(NSArray *)changedItems;

@end

@interface SJDatabaseViewDataSource : NSObject

@property (nonatomic, weak) id<SJDatabaseViewDataSourceDelegate> delegate;

- (id)initWithMappings:(YapDatabaseViewMappings *)viewMappings
              database:(YapDatabase *)database;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

@end
