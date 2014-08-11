//
//  NSDictionary_ickStream.h
//  ickComm
//
//  Created by Jörg Schwieder on 07.07.09.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NumericalConverters

- (BOOL)boolValue;
- (double)doubleValue;
- (float)floatValue;
- (NSInteger)integerValue;
- (int)intValue;
- (unsigned int)unsignedIntValue;
- (long long)longLongValue;

@end


# define IPNumerical NSObject<NumericalConverters>


@interface NSDictionary(ickStream)

- (id)nonNullObjextForKey:(id)key;
- (NSString *)stringForKey:(id)key;
- (NSNumber *)numForKey:(id)key;
- (NSNumber *)intNumForKey:(id)key;
- (NSInteger)intForKey:(id)key;
- (IPNumerical *)numericalForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key;
- (NSArray *)arrayForKey:(id)key;
- (id)objectForCaseInsensitiveKey:(NSString *)key;
- (id)nonNullObjextForCaseInsensitiveKey:(NSString *)key;
- (NSString *)stringForCaseInsensitiveKey:(NSString *)key;
+ (NSDictionary *)dictionaryFromTabSeparatedFile:(NSString *)fileName;

@end


// Add support for subscripting to the iOS 5 SDK.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
@interface NSObject(ickStream_subscripts)

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;

@end
#endif


