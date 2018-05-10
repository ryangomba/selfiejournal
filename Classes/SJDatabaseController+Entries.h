//
//  SJDatabase+Entries.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJDatabaseController.h"

#import "SJEntry.h"

static NSString * const kAllEntriesViewName = @"allEntries";
static NSString * const kAllItemsGroup = @"allItems";

@interface SJDatabaseController (Entries)

+ (void)saveEntry:(SJEntry *)entry;
+ (void)deleteEntry:(SJEntry *)entry;

+ (YapDatabaseView *)allEntriesView;

@end
