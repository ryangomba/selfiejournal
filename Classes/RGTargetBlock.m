// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "RGTargetBlock.h"

@interface RGTargetBlock () {
    id _block;
}

@end

@implementation RGTargetBlock
- (id)initWithBlock:(id)block {
    NSParameterAssert(block);
    if ((self = [super init])) {
        _block = block;
    }
    return self;
}

- (void)invoke {
    void(^block)(void) = _block;
    block();
}

- (void)invoke:(id)object {
    void(^block)(id) = _block;
    block(object);
}

@end
