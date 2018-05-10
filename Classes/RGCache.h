// Copyright 2014-present Ryan Gomba. All rights reserved.

@interface RGCache : NSObject

/*
 This class is thread safe.
 Objects cached in memory are automatically evicted when memory is low.
 Objects cached on disk are evicted using the LRU scheme when diskCapacity is exceeded.
 Completion blocks are called on a default priority queue.
 */

@property (nonatomic, assign) NSUInteger diskCapacity;
@property (nonatomic, assign) NSUInteger maxObjectCount;

- (id)initWithName:(NSString *)name
      diskCapacity:(NSUInteger)diskCapacity
    maxObjectCount:(NSUInteger)maxObjectCount;

- (id)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key completion:(void(^)(id object))completion;

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key completion:(void(^)(void))completion;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end
