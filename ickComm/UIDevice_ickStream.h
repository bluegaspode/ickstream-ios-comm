//
//  UIDevice_ickStream.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 22.03.11.
//  Copyright 2011 Du!Business GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIDevice(ickStream)

- (BOOL)isPad;
- (BOOL)isPhone;
- (BOOL)isIOS4;
- (BOOL)isIOS5;
- (BOOL)isIOS6;
- (BOOL)isIOS7;
- (BOOL)isMinVersion:(NSString *)minVersion;
- (BOOL)canBlur;

@end


#define IS_IOS7 ([UIDevice currentDevice].isIOS7)
