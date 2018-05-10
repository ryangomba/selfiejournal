//
//  SJDatabase.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YapDatabase.h"
#import "YapDatabaseView.h"

@interface SJDatabaseController : NSObject

+ (YapDatabase *)database;

+ (void)addDependent:(id)dependent
        forExtension:(YapDatabaseExtension *)extension
       extensionName:(NSString *)extensionName;

+ (void)removeDependent:(id)dependent
      forExtensionNamed:(NSString *)extensionName;

// DEBUG

+ (void)flushDatabase;

@end
