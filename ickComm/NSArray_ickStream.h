//
//  NSArray_iPeng.h
//  iPengApp
//
//  Created by Jörg Schwieder on 27.07.11.
//  Copyright 2011 Du!Business GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(iPeng)

- (id)nonNullObjextAtIndex:(NSUInteger)idx;
- (NSDictionary *)dictionaryAtIndex:(NSUInteger)idx;
- (BOOL)hasEqualContentToArray:(NSArray *)array fast:(BOOL)fast;
- (BOOL)hasEqualContentToArray:(NSArray *)array;

@end

