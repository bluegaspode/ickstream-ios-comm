//
//  UIDevice_ickStream.m
//  ickComm
//
//  Created by Jörg Schwieder on 22.03.11.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "UIDevice_ickStream.h"


@implementation UIDevice(ickStream)

- (BOOL)isPad {
	static BOOL _isPad = NO;
	static BOOL done = NO;
	if (!done) {
		_isPad = [self.model hasPrefix:@"iPad"];
		done = YES;
	}
	return _isPad;
}

- (BOOL)isPhone {
	static BOOL _isPhone = NO;
	static BOOL done = NO;
	if (!done) {
		_isPhone = [self.model hasPrefix:@"iPhone"];
		done = YES;
	}
	return _isPhone;
}

- (BOOL)isIOS4 {
	static BOOL _isIOS4 = NO;
	static BOOL done = NO;
	
	if (!done) {
		if ([self.systemVersion compare:@"4" options:NSNumericSearch] != NSOrderedAscending)
			_isIOS4 = YES;
		done = YES;
	}
	return _isIOS4;
}

- (BOOL)isIOS5 {
	static BOOL _isIOS5 = NO;
	static BOOL done5 = NO;
	
	if (!done5) {
		if ([self.systemVersion compare:@"5" options:NSNumericSearch] != NSOrderedAscending)
			_isIOS5 = YES;
		done5 = YES;
	}
	return _isIOS5;
}

- (BOOL)isIOS6 {
	static BOOL _isIOS6 = NO;
	static BOOL done6 = NO;
	
	if (!done6) {
		if ([self.systemVersion compare:@"6" options:NSNumericSearch] != NSOrderedAscending)
			_isIOS6 = YES;
		done6 = YES;
	}
	return _isIOS6;
}

- (BOOL)isIOS7 {
	static BOOL _isIOS7 = NO;
	static BOOL done7 = NO;
	
	if (!done7) {
		if ([self.systemVersion compare:@"7" options:NSNumericSearch] != NSOrderedAscending)
			_isIOS7 = YES;
		done7 = YES;
	}
	return _isIOS7;
}

- (BOOL)canBlur {
    static BOOL _canBlur = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!IS_IOS7) {
            _canBlur = NO;
        } else if ([self.model hasPrefix:@"iPhone"]) {
            _canBlur = ([self.model compare:@"iPhone4" options:NSNumericSearch] != NSOrderedAscending);
        } else if ([self.model hasPrefix:@"iPad"]) {
            _canBlur = ([self.model compare:@"iPad3,4" options:NSNumericSearch] != NSOrderedAscending) ||
                        ([self.model compare:@"iPad4" options:NSNumericSearch] != NSOrderedAscending);
        } else if ([self.model hasPrefix:@"iPod"]) {
            _canBlur = ([self.model compare:@"iPod4" options:NSNumericSearch] != NSOrderedAscending);
        }
    });
    return _canBlur;
}

- (BOOL)isMinVersion:(NSString *)minVersion {
	return ([self.systemVersion compare:minVersion options:NSNumericSearch] != NSOrderedAscending);
}

@end
