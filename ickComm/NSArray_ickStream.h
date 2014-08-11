//
//  NSArray_ickStream.h
//  ickComm
//
//  Created by Jörg Schwieder on 27.07.11.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(iPeng)

- (id)nonNullObjextAtIndex:(NSUInteger)idx;
- (NSDictionary *)dictionaryAtIndex:(NSUInteger)idx;
- (BOOL)hasEqualContentToArray:(NSArray *)array fast:(BOOL)fast;
- (BOOL)hasEqualContentToArray:(NSArray *)array;

@end

