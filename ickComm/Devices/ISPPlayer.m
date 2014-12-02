//
//  ISPPlayer.m
//  ickComm
//
//  Created by Jörg Schwieder on 06.06.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "ISPPlayer.h"
#import "ISPDeviceCloud.h"
#import "ISPDeviceMyself.h"

@interface ISPPlayer ()


@end

@implementation ISPPlayer

@synthesize status = _status;
@synthesize playlistInfo = _playlistInfo;
@synthesize notificationData = _notificationData;
@synthesize playlistTracks = _playlistTracks;

- (id)initWithUUID:(NSString *)aUuid andType:(ickP2pServicetype_t)type {
    self = [super initWithUUID:aUuid andType:type];
    return self;
}

- (void)handleDeviceNotification:(NSString *)method params:(NSDictionary *)params {
    if (!method)
        return;
    if ([method isEqualToString:@"playerStatusChanged"]) {
        if (params)
            self.status = params;
    } else if ([method isEqualToString:@"playbackQueueChanged"]) {
        if (params)
            self.playlistInfo = params;
    } else {
        NSMutableDictionary *newNotificationData = [[NSMutableDictionary alloc] init];
        newNotificationData[@"method"] = method;
        if (params) {
            newNotificationData[@"params"] = params;
        }
        self.notificationData = newNotificationData;
    }
}

- (BOOL)validated {
    BOOL isRegistered = [[self.status stringForKey:@"cloudCoreStatus"] isEqualToString:@"REGISTERED"];
    return self.known && isRegistered;
}

- (void)setStatus:(NSDictionary *)newStatus {
    BOOL isRegistered = [[self.status stringForKey:@"cloudCoreStatus"] isEqualToString:@"REGISTERED"];
    BOOL newIsRegistered = [[newStatus stringForKey:@"cloudCoreStatus"] isEqualToString:@"REGISTERED"];
    // registration state just changed to "registered"
    if (!isRegistered && newIsRegistered) {
        self.known = NO;    // can't be known - state just changed
        [self checkAccount];
    }
    _status = newStatus;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerStatusChanged"
                                                        object:self
                                                      userInfo:newStatus];
    if (isRegistered != newIsRegistered) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerListChangedNotification"
                                                            object:self
                                                          userInfo:@{@"type" : @"other"}];
    }
}

- (void)setNotificationData:(NSMutableDictionary *)notificationData {
    _notificationData[@"method"] = notificationData[@"method"];
    _notificationData[@"params"] = notificationData[@"params"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerNotification"
                                                        object:self
                                                      userInfo:notificationData];
}

- (void)setPlaylistInfo:(NSDictionary *)newInfo {
    _playlistInfo = newInfo;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlaylistChanged"
                                                        object:self
                                                      userInfo:newInfo];
}

- (void)requestConfigurationForDevice {
    [super requestConfigurationForDevice];
    [ISPRequest automaticRequestWithDevice:self
                                   service:nil
                                    method:@"getPlayerStatus"
                                    params:nil
                             withResponder:^(NSDictionary *result, ISPRequest *request) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = result;
        });
    } withErrorResponder:^(NSString *errorString, ISPRequest *request) {
        NSLog(@"status error");
    }];
}


- (void)registerPlayer {
    NSDictionary *params = @{@"id" : self.uuid, @"name" : self.name, @"applicationId" : [ISPDeviceMyself myselfApplicationId]};

    [ISPRequest automaticRequestWithDevice:[ISPDeviceCloud singleton] service:nil method:@"createDeviceRegistrationToken" params:params
                             withResponder:^(NSDictionary *result, ISPRequest *request) {
        NSString *token = [result stringForKey:@"text"];
        NSDictionary *setPlConfigParams = @{@"deviceRegistrationToken" : token};
        [ISPRequest automaticRequestWithDevice:self service:@"" method:@"setPlayerConfiguration" params:setPlConfigParams];
    }
                        withErrorResponder:^(NSString *errorString, ISPRequest *request) {
        NSLog(@"status error");
    }
    ];


}

@end
