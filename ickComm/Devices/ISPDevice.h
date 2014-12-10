//
//  ISPDevice.h
//  ickComm
//
//  Created by Jörg Schwieder on 11.04.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//
// This is the general Objecticve C device wrapper.
// A device currently can be a controller or a player

#import <Foundation/Foundation.h>
#import "ISPRequest.h"
#import "ickP2p.h"

@interface ISPDevice : NSObject

@property (strong, nonatomic)   NSString                    * uuid;
@property (nonatomic)           ickP2pServicetype_t         ickType;
@property (strong, nonatomic, readonly)   NSString *        hardwareId;
@property (strong, nonatomic, readonly)   NSString *        defaultName;
@property (strong, nonatomic, readonly)   NSString *        playerModel;
@property (strong, nonatomic, readwrite)   NSString *        userId;
@property (strong, nonatomic)   NSString *                  name;
@property (strong, readonly)      NSURL *                     url;
@property (strong, nonatomic)    NSMutableDictionary *       services;
@property (nonatomic) BOOL                                  known;
@property (nonatomic, readonly) BOOL                        validated;

+ (void)registerInDeviceList:(ISPDevice *)newDevice;
+ (ISPDevice *)findDeviceWithUUID:(NSString *)aUuid andType:(ickP2pServicetype_t)type;
- (id)initWithUUID:(NSString *)aUuid andType:(ickP2pServicetype_t)type;
- (BOOL)configureWithUUID:(const char *)cUUID;
- (void)configureWithURLString:(const char *)cURL;

- (void)checkAccount;
- (void)requestConfigurationForPlayer;

- (void)setUserId:(NSString *)userId;

- (NSURL *)urlForService:(NSString *)serviceId;
+ (void)registerService:(NSString *)aServiceId ofType:(NSString *)serviceType forDevice:(ISPDevice *)aDevice;
+ (ISPDevice *)findDeviceWithServiceId:(NSString *)serviceId;
+ (NSString *)findServicesOfType:(NSString *)type;
+ (NSString *)findPreferredServiceOfType:(NSString *)type;
+ (void)removeFromDeviceList:(ISPDevice *)oldDevice;
- (void)removeFromDeviceList;

- (NSString *)displayName;

+ (Class)atomicRequestClass;
- (Class)atomicRequestClass;
- (NSObject<ISPAtomicRequestProtocol> *)atomicRequestForService:(NSString *)aServiceId owner:(ISPRequest *)owner;

- (void)handleDeviceNotification:(NSString *)method params:(NSDictionary *)params;

+ (void)initializeIckStreamWithDeviceName:(NSString *)aName;
+ (void)suspendIckStream;
+ (ickP2pContext_t *)ickP2pContext;

+ (NSArray *)allDevicesOfType:(ickP2pServicetype_t)type;
+ (NSArray *)allServices;

@end
