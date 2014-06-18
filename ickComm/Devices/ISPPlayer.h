//
//  ISPPlayer.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 06.06.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPDevice.h"

@interface ISPPlayer : ISPDevice

@property (strong, nonatomic, readwrite) NSDictionary * status;
@property (strong, nonatomic, readwrite) NSDictionary * playlistInfo;
@property (strong, nonatomic, readwrite) NSArray * playlistTracks;

@end
