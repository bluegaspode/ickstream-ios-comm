//
//  ISPDeviceCloud.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 13.04.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPDevice.h"

@interface ISPDeviceCloud : ISPDevice

+ (ISPDeviceCloud *)singleton;
- (void)getCloudServices;
- (void)getDevicesForUser;
+ (NSString *)applicationId;

@end
