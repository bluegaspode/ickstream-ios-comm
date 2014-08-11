//
//  NSDictionary_ichStream.m
//  ickComm
//
//  Created by Jörg Schwieder on 07.07.09.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "NSDictionary_ickStream.h"

@implementation NSDictionary(ickStream)

- (id)nonNullObjextForKey:(id)key {
	id temp = [self objectForKey:key];
	if (temp == [NSNull null])
		return nil;
	return temp;
}

- (NSString *)stringForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || [temp isKindOfClass:[NSString class]])
		return temp;
	if (temp == [NSNull null])
		return nil;
	return [NSString stringWithFormat:@"%@", temp];
}

- (NSNumber *)numForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || [temp isKindOfClass:[NSNumber class]])
		return temp;
	return nil;
}

- (NSNumber *)intNumForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || [temp isKindOfClass:[NSNumber class]])
		return temp;
	if ([temp isKindOfClass:[NSString class]])
		return [NSNumber numberWithInt:[temp intValue]];
	return nil;
}

- (NSInteger)intForKey:(id)key {
	id temp = [self objectForKey:key];
	if ([temp isKindOfClass:[NSNumber class]] || [temp isKindOfClass:[NSString class]])
		return [temp intValue];
	return 0;
}

- (IPNumerical *)numericalForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || 
			[temp isKindOfClass:[NSNumber class]] ||
			[temp isKindOfClass:[NSString class]])
		return temp;
	return nil;
}

- (NSDictionary *)dictionaryForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || [temp isKindOfClass:[NSDictionary class]])
		return temp;
	return nil;
}

- (NSArray *)arrayForKey:(id)key {
	id temp = [self objectForKey:key];
	if (!temp || [temp isKindOfClass:[NSArray class]])
		return temp;
	return nil;
}

- (id)objectForCaseInsensitiveKey:(NSString *)key {
	if (![key isKindOfClass:[NSString class]])
		return [self objectForKey:key];
	for (NSString * itemKey in [self allKeys]) {
		if ([itemKey isKindOfClass:[NSString class]])
			if ([itemKey caseInsensitiveCompare:key] == NSOrderedSame)
				return [self objectForKey:itemKey];
	}
	return nil;
}

- (id)nonNullObjextForCaseInsensitiveKey:(NSString *)key {
	if (![key isKindOfClass:[NSString class]])
		return [self nonNullObjextForKey:key];
	for (NSString * itemKey in [self allKeys]) {
		if ([itemKey isKindOfClass:[NSString class]])
			if ([itemKey caseInsensitiveCompare:key] == NSOrderedSame) {
				id temp = [self objectForKey:itemKey];
				if (temp == [NSNull null])
					return nil;
				return temp;				
			}
	}
	return nil;
}

- (NSString *)stringForCaseInsensitiveKey:(NSString *)key {
	if (![key isKindOfClass:[NSString class]])
		return [self stringForKey:key];
	id temp;
	for (NSString * itemKey in [self allKeys]) {
		if ([itemKey isKindOfClass:[NSString class]])
			if ([itemKey caseInsensitiveCompare:key] == NSOrderedSame) {
				temp = [self objectForKey:itemKey];
				if (!temp || [temp isKindOfClass:[NSString class]])
					return temp;
				if (temp == [NSNull null])
					return nil;
				return [NSString stringWithFormat:@"%@", temp];				
			}
	}
	return nil;
}

+ (NSDictionary *)dictionaryFromTabSeparatedFile:(NSString *)fileName {
//	NSString * path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];

	NSString * fullFileString = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
	NSScanner * fileScanner = [NSScanner scannerWithString:fullFileString];
	[fileScanner setCharactersToBeSkipped:nil];
	NSString * line;
	NSRange range;
	NSCharacterSet * whitespace = [NSCharacterSet whitespaceCharacterSet];
	NSString * trimmedLine;
	NSMutableDictionary * wholeDict = [NSMutableDictionary dictionaryWithCapacity:50];
	NSMutableDictionary * detailedDictionary = nil;
	NSString * currentKey = nil;
	
	while (![fileScanner isAtEnd]) {
        @autoreleasepool {
            line = nil;
            [fileScanner scanUpToString:@"\n" intoString:&line];
            range = [line rangeOfString:@"#"];
            trimmedLine = (range.location != NSNotFound) ? [line substringToIndex:range.location] : line;
            if ([trimmedLine length] && [(trimmedLine = [trimmedLine stringByTrimmingCharactersInSet:whitespace]) length]) {
                if ([whitespace characterIsMember:[line characterAtIndex:0]]) {
    // whitespace? This is a line containing a language string
                    NSArray * arr = [trimmedLine componentsSeparatedByString:@"\t"];
                    if ([arr count] > 1) {
                        NSString * language = [arr objectAtIndex:0];
                        if ([arr count] < 3)
                            [detailedDictionary setObject:[arr objectAtIndex:1] forKey:language];
                        else {
                            NSMutableArray * temp = [NSMutableArray arrayWithArray:arr];
                            [temp removeObjectAtIndex:0];
                            [detailedDictionary setObject:[temp componentsJoinedByString:@"\t"]  forKey:language];
                        }
                    }
                } else {
    // No whitespace? This is a line containing a tag
                    if ([detailedDictionary count])
                        [wholeDict setObject:detailedDictionary forKey:currentKey];
                    detailedDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
                    currentKey = trimmedLine;
                } 
            }
            [fileScanner scanString:@"\n" intoString:nil];
		}
	}
	if ([detailedDictionary count])
		[wholeDict setObject:detailedDictionary forKey:currentKey];
	if ([wholeDict count])
		return wholeDict;
	else
		return nil;
}

@end
