//
//  NSString_iPeng.h
//  iPengApp
//
//  Created by Jörg Schwieder on 07.08.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(ickStream)

- (NSString *)getSHA1Hash;
- (unsigned int)unsignedIntValue;
- (NSString *)stringByAppendingURLPathComponent:(NSString *)str;
+ (NSString*)base64EncodedString:(NSData *)data;

@end
