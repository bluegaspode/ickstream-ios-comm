//
//  ISPDeviceMyself.h
//  ickComm
//
//  Created by Jörg Schwieder on 11.05.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//
// This is a wrapper for any logic that refers to the app itself - there are still two classes to be used because we might be either one of a player or a server....

#import <Foundation/Foundation.h>
#import "ISPDevice.h"

@interface ISPDeviceMyself : ISPDevice

@property (strong, readonly, nonatomic) NSString * deviceAuthorization;

+ (NSString *)myselfToken;
+ (NSString *)myselfUserId;

+ (void)setToken:(NSString *)token andUserId:(NSString *)userId;

+ (void)clearMyselfToken;
+ (NSString *)myselfUUID;
+ (NSString *)myselfUserToken;
+ (void)clearMyselfUserToken;
+ (NSString *)deviceAuthorization;
+ (void)setApplicationId:(NSString *)newId;

+ (NSString *)myselfApplicationId;

+ (ISPDeviceMyself *)findMyselfOfType:(ickP2pServicetype_t)type;
- (id)initWithType:(ickP2pServicetype_t)type;

+ (void)registerDevice;
+ (void)hasEnteredToken:(NSString *)token;

@end
