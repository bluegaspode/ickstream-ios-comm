//
//  NSArray_iPeng.m
//  iPengApp
//
//  Created by Jörg Schwieder on 27.07.11.
//  Copyright 2011 Du!Business GmbH. All rights reserved.
//

#import "NSArray_ickStream.h"


@implementation NSArray(ickStream)


- (id)nonNullObjextAtIndex:(NSUInteger)idx {
    if (idx >= [self count])
        return nil;
    id temp = [self objectAtIndex:idx];
    if ([temp isKindOfClass:[NSNull class]])
        return nil;
    return temp;
}

- (NSDictionary *)dictionaryAtIndex:(NSUInteger)idx {
    if (idx >= [self count])
        return nil;
    id temp = [self objectAtIndex:idx];
    if (![temp isKindOfClass:[NSDictionary class]])
        return nil;
    return temp;
}

// fast means that it's assumed that there are no dupes in any of the array. Much faster but leads to wrong results if that doesn't hold true
- (BOOL)hasEqualContentToArray:(NSArray *)array fast:(BOOL)fast {
    if (!array)
        return NO;
    if ([self count] != [array count])
        return NO;
    id item;
    for (item in self)
        if (![array containsObject:item])
            return NO;
    if (fast)
        return YES;
    for (item in array)
        if (![self containsObject:item])
            return NO;
    return YES;
}

- (BOOL)hasEqualContentToArray:(NSArray *)array {
    return [self hasEqualContentToArray:array fast:NO];
}



@end
