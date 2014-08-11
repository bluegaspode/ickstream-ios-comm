//
//  NSString_ickStream.h
//  ickComm
//
//  Created by Jörg Schwieder on 07.08.09.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(ickStream)

- (NSString *)getSHA1Hash;
- (unsigned int)unsignedIntValue;
- (NSString *)stringByAppendingURLPathComponent:(NSString *)str;
+ (NSString*)base64EncodedString:(NSData *)data;

@end
