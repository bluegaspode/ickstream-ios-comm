//
//  NSString_iPeng.m
//  iPengApp
//
//  Created by Jörg Schwieder on 07.08.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSString_ickStream.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <string.h>


@implementation NSString(ickStream)

- (NSString *)getSHA1Hash {
    CC_SHA1_CTX ctx;
    uint8_t * hashBytes = NULL;
    NSMutableString * hash = [NSMutableString stringWithCapacity:(CC_SHA1_DIGEST_LENGTH * 2)];
    
    // Malloc a buffer to hold hash.
    hashBytes = malloc(CC_SHA1_DIGEST_LENGTH * sizeof(uint8_t) );
	if (!hashBytes)
		return nil;
    memset((void *)hashBytes, 0x0, CC_SHA1_DIGEST_LENGTH);
	    
	const char * utf8String = [self UTF8String];
    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *)utf8String, strlen(utf8String));
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);
    
    // Build up the SHA1 string.
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		[hash appendFormat:@"%02x", hashBytes[i]];	
	    
    free(hashBytes);
    
    return hash;
}

- (unsigned int)unsignedIntValue {
	long long lvalue = [self longLongValue];
	return (unsigned int)(lvalue % UINT_MAX);
}

- (NSString *)stringByAppendingURLPathComponent:(NSString *)str {
    BOOL selfSlash = [self hasSuffix:@"/"];
    BOOL newSlash = [str hasPrefix:@"/"];
    
    if (([str length] == 1) && newSlash)
        if (selfSlash)
            return self;
        else
            return [self stringByAppendingString:@"/"];
    if (selfSlash && newSlash)
        str = [str substringFromIndex:1];
    else if (!selfSlash && !newSlash)
        str = [NSString stringWithFormat:@"/%@", str];
    return [self stringByAppendingString:str];
}

+ (NSString*)encodeBase64Raw:(const uint8_t*)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data
                                  encoding:NSASCIIStringEncoding];
}

+ (NSString*)base64EncodedString:(NSData *)data {
    return [self encodeBase64Raw:data.bytes length:data.length];
}

@end
