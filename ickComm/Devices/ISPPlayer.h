//
//  ISPPlayer.h
//  ickComm
//
//  Created by Jörg Schwieder on 06.06.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "ISPDevice.h"

@interface ISPPlayer : ISPDevice

@property (strong, nonatomic, readwrite) NSDictionary * status;
@property (strong, nonatomic, readwrite) NSMutableDictionary *notificationData;
@property (strong, nonatomic, readwrite) NSDictionary * playlistInfo;
@property (strong, nonatomic, readwrite) NSArray * playlistTracks;

- (void)registerPlayer;
@end
