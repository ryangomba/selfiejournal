// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "NSString+MD5.h"

#import <MobileCoreServices/UTType.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *)MD5 {
    // Create pointer to the string as UTF8
    const char *charPointer = [self UTF8String];

    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(charPointer, (CC_LONG) strlen(charPointer), md5Buffer);

    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", md5Buffer[i]];
    }

    return md5String;
}

@end
