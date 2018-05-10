// Copyright 2014-present Ryan Gomba. All rights reserved.

#import <Foundation/Foundation.h>

// NSTimers and friends retain the target. So to avoid retain cycles use the following pattern:
//    __weak id weakself = self;
//    id target = [[MXTargetBlock alloc] initWithBlock:^(id object) {
//        id strongself = weakself;
//        [strongself invoke:object];
//    }];
//    _displayLink = [CADisplayLink displayLinkWithTarget:target selector:@selector(invoke:)];

@interface RGTargetBlock : NSObject
- (id)initWithBlock:(id)block;
- (void)invoke;             // invokes the block without an argument
- (void)invoke:(id)object;  // invokes the block with an argument
@end
