//
//  ISPDevice.m
//  ickComm
//
//  Created by Jörg Schwieder on 11.04.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "ISPDevice.h"
#import "ISPPlayer.h"
#import "ISPRHttpRequest.h"
#import "ISPRequest.h"
#import "ISPRWebsocketRequest.h"
#import "ISPDeviceMyself.h"
#import "ISPDeviceCloud.h"

static NSMutableDictionary * _allDevices = nil;
static NSMutableArray * _allServices = nil;

static ickP2pContext_t * _ickP2pContext = NULL;


@interface ISPDevice()

@property (strong, nonatomic, readwrite) NSString * defaultName;

+ (void)accessTokenAcquired:(NSNotification *)notification;
- (void)requestConfigurationForDevice;
- (void)requestConfigurationForService;

@end


#define DEVICE_UUID(string,type) [NSString stringWithFormat:@"%02d-%@", type, string]

@implementation ISPDevice
@synthesize url=_url;

+ (void)initialize {
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _allDevices = [[NSMutableDictionary alloc] initWithCapacity:5];
        _allServices = [[NSMutableArray alloc] initWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(accessTokenAcquired:)
                                                     name:@"ISPAccessTokenAcquiredNotification"
                                                   object:nil];
    });
}

static void gotADevice(ickP2pContext_t *ictx, const char * UUID, ickP2pDeviceState_t change, ickP2pServicetype_t type) {
    //    static void gotADevice(const char * UUID, ickDiscoveryCommand_t change, ickDeviceServicetype_t type) {
    //TBD remove devices, too
    
    char * IP = ickP2pGetDeviceLocation(ictx, UUID);
    NSString * uuidString = [NSString stringWithUTF8String:UUID];
    
    NSString * strChange = nil;
    switch (change) {
        case ICKP2P_CONNECTED:
            strChange = @"added";
            break;
            //case ICKDISCOVERY_UPDATE_DEVICE:
            //strChange = @"updated";
            break;
        case ICKP2P_DISCONNECTED:
            strChange = @"removed";
            break;
        default:
            strChange = @"irritated";
            break;
    }
    
    NSLog(@"\nDevice %@: UUID: %s, IP: %s, type: %d\n\n", strChange, UUID, IP, type);
    
    //    char * msg = NULL;
    //    asprintf(&msg, "Hello from %s", [[UIDevice currentDevice].name UTF8String]);
    
    //    ickDeviceSendMsg(UUID, msg, strlen(msg) + 1);
    //    free(msg);
    
    __strong ISPDevice * aDevice = [ISPDevice findDeviceWithUUID:uuidString andType:type];
    
    
    switch (change) {
        case ICKP2P_CONNECTED: {
            if (!aDevice) {
                if (type & ICKP2P_SERVICE_PLAYER)
                    aDevice = [[ISPPlayer alloc] initWithUUID:uuidString andType:type];
                // don't create root devices, have nothing to talk to them and it means described devices get created with a wrong type.
                else if (type & ICKP2P_SERVICE_SERVER_GENERIC) // TODO: we might have two devices with the same UUID, a player and a server. This means in that case the server will be ignored!!!
                    aDevice = [[ISPDevice alloc] initWithUUID:uuidString andType:type];
                if (!aDevice)
                    return;
            }
            
            if ([aDevice configureWithUUID:UUID] || !aDevice.url) {
                [aDevice configureWithURLString:IP];
            }
            // nope - we only do this whenever the status message comes in
            //[aDevice checkAccount];
            
            if (type & ICKP2P_SERVICE_PLAYER) {
                [aDevice requestConfigurationForDevice];
            // See above: server would be ignored!!
            } else if (type & ICKP2P_SERVICE_SERVER_GENERIC)
                [aDevice requestConfigurationForService];
        }
            break;
            
        case ICKP2P_DISCONNECTED: {
            if (!aDevice)
                return;
            [aDevice removeFromDeviceList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerListChangedNotification"
                                                                    object:aDevice
                                                                  userInfo:nil];
            });
        }
            break;
        default:
            break;
    }    
}


static BOOL ickStreamActive = NO;

+ (ickP2pContext_t *)ickP2pContext {
    return _ickP2pContext;
}

- (ickP2pContext_t *)ickP2pContext {
    return _ickP2pContext;
}

+ (void)initializeIckStreamWithDeviceName:(NSString *)aName {
    if (ickStreamActive)
        return;
    ickStreamActive = YES;
    if (!aName)
        aName = [UIDevice currentDevice].name;
    
    _ickP2pContext = ickP2pCreate(aName.UTF8String,
                                  [ISPDeviceMyself myselfUUID].UTF8String,
                                  NULL,
                                  30,   //lifetime
                                  0,    //port
                                  ICKP2P_SERVICE_PLAYER | ICKP2P_SERVICE_CONTROLLER,   // for now: we know this. But it#s really bad style
                                  NULL);
    
    ickP2pAddInterface(_ickP2pContext, "en0", NULL);
    ickP2pAddInterface(_ickP2pContext, "en1", NULL);
    ickP2pAddInterface(_ickP2pContext, "127.0.0.1", NULL);
    ickP2pRegisterDiscoveryCallback(_ickP2pContext, &gotADevice);
    [ISPRWebsocketRequest registerCallback]; //uuuuuuugggggllllllyyyyyyyyy
    ickP2pSetHttpDebugging(_ickP2pContext, true);
    ickP2pUpnpLoopback( _ickP2pContext, true );
    ickP2pResume(_ickP2pContext);
    
    //ickDeviceRegisterDeviceCallback(&gotADevice);
    //ickInitDiscovery([[ISPDeviceMyself myselfUUID] UTF8String], "en0", NULL);
    //ickDiscoverySetupConfigurationData([aName UTF8String], NULL);


    
    //ickP2pResume(_ickP2pContext);

}

+ (void)suspendIckStream {
    if (!ickStreamActive)
        return;
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"expirationHandler");
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        ickP2pEnd(_ickP2pContext, NULL);
        [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
        ickStreamActive = NO;
    });
}

+ (ISPDevice *)findDeviceWithUUID:(NSString *)aUuid andType:(ickP2pServicetype_t)type {
    return [_allDevices objectForKey:DEVICE_UUID(aUuid, type)];
}

+ (NSArray *)allDevicesOfType:(ickP2pServicetype_t)type {
    NSMutableArray * devices = [NSMutableArray arrayWithCapacity:2];
    for (NSString * key in [_allDevices allKeys]) {
        ISPDevice * device = [_allDevices objectForKey:key];
        if (device.ickType & type)
            [devices addObject:device];
    }
    if (![devices count])
        return nil;
    return devices;
}


+ (void)registerInDeviceList:(ISPDevice *)newDevice {
    NSLog(@"registerDeviceInList: %@, %@", newDevice.uuid, newDevice);
    [_allDevices setValue:newDevice forKey:DEVICE_UUID(newDevice.uuid, newDevice.ickType)];    
}

+ (void)removeFromDeviceList:(ISPDevice *)oldDevice {
    NSLog(@"ISPDevice removeFromDeviceList:%@", oldDevice.uuid);
    if (!oldDevice.uuid)
        NSLog(@"unregistering Cloud Server");
    [_allDevices removeObjectForKey:DEVICE_UUID(oldDevice.uuid, oldDevice.ickType)];
}

- (void)removeFromDeviceList {
    [[self class] removeFromDeviceList:self];
}

- (id)initWithUUID:(NSString *)aUuid andType:(ickP2pServicetype_t)type {
    NSLog(@"device:initWithUUID:%@ andType:%d", aUuid, (int)type);
    id tmp = [ISPDevice findDeviceWithUUID:aUuid andType:type];
    if (tmp) {
        NSLog(@"device found");
        self = nil;
        self = tmp;
        return self;
    }
/*    if (type == ICKDEVICE_PLAYER) {
        self = nil;
        self = [ISPPlayer alloc];
    }*/
    self = [super init];
    if (self) {
        self.uuid = aUuid;
        self.ickType = type;
        [[self class] registerInDeviceList:self];
        _services = nil;
        _known = NO;
        _defaultName = nil;
        _name = nil;
    }
    return self;
}

// needs to be called from callback thread!
- (BOOL)configureWithUUID:(const char *)cUUID {
    BOOL change = NO;
    
    char * cstr = ickP2pGetDeviceName([ISPDevice ickP2pContext], cUUID);
    NSString * string = nil;
    if (cstr)
        string = [NSString stringWithUTF8String:cstr];
    if (string && ![string isEqualToString:_defaultName]) {
        self.defaultName = string;
        change = YES;
    }
    return change;
}

#pragma mark - cloud ops {

- (void)checkAccount {
    
    // For now, devices which use different cloud urls are on different accounts
    // But ignore http vs. https because some players are still using http
    
    BOOL(^compareURLSchemeInsensitive)(NSString *, NSString *) = ^(NSString * url1, NSString * url2) {
        url1 = [url1 stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        url1 = [url1 stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        url2 = [url2 stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        url2 = [url2 stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        return [url1 isEqualToString:url2];
    };
    
    if (self.cloudURL && !compareURLSchemeInsensitive(self.cloudURL, ISPDeviceCloud.singleton.cloudURL)) {
        self.known = NO;
        return;
    }
    
    [ISPRequest automaticRequestWithDevice:[ISPDeviceCloud singleton]
                                   service:nil
                                    method:@"getDevice" 
                                    params:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            self.uuid, @"deviceId", nil]
                             withResponder:^(NSDictionary *result, ISPRequest *request) {
                                 BOOL changed = NO;
                                 if (!self.known) {
                                     self.known = YES;
                                     changed = YES;
                                 }
                                 NSString * knownName = [result stringForKey:@"name"];
                                 if (![knownName isEqualToString:self.name]) {
                                     self.name = knownName;
                                     changed = YES;
                                 }
                                 if (changed)
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerListChangedNotification" object:self userInfo:nil];
                             } withErrorResponder:^(NSString *errorString, ISPRequest *request) {
                                 NSLog(@"%@", errorString);
                             }];
}

- (void)requestConfigurationForDevice {
    [ISPRequest automaticRequestWithDevice:self
                                   service:nil 
                                    method:@"getPlayerConfiguration" 
                                    params:[NSDictionary dictionary]
                             withResponder:^(NSDictionary *result, ISPRequest *request) {
                                 NSString * string = [result stringForKey:@"hardwareId"];
                                 BOOL change = NO;
                                 if (string) {
                                     _hardwareId = string;
                                     change = YES;
                                 }
                                 
                                 string = [result stringForKey:@"playerName"];
                                 if (string) {
                                     _defaultName = string;
                                     change = YES;
                                 }
                                 
                                 string = [result stringForKey:@"cloudCoreUrl"];
                                 if (string) {
                                     _cloudURL = string;
                                     change = YES;
                                 }
                                 
                                 if (change)
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPPlayerListChangedNotification" object:self userInfo:nil];
                             } withErrorResponder:^(NSString *errorString, ISPRequest *request) {
                                 NSLog(@"can't request device configuration: %@", self.services);
                             }];

}

- (void)requestConfigurationForService {
    [ISPRequest automaticRequestWithDevice:self
                                   service:nil 
                                    method:@"getServiceInformation" 
                                    params:[NSDictionary dictionary]
                             withResponder:^(NSDictionary *result, ISPRequest *request) {                                 
                                 NSLog(@"Service Information: %@", result);
                                 NSString * serviceId = [result stringForKey:@"id"];
                                 if (!serviceId)
                                     return;
                                 NSString * type = [result stringForKey:@"type"];
                                 if (!type) type = @"";
                                 NSString * name = [result stringForKey:@"name"];
                                 //                                 if (![type isEqualToString:@"content"])
                                 //                                     return;        // Only use content services for now
                                 if ([ISPDevice findDeviceWithServiceId:serviceId])
                                     return;        // we already registered this service
                                 result = [result mutableCopy];
                                 if (!_services)
                                     _services = [NSMutableDictionary dictionaryWithCapacity:1];
                                 _services[serviceId] = result;
                                 [ISPDevice registerService:serviceId ofType:type forDevice:self];

                                 // this stuff needs to be run on the main thread .... I can't add service descriptions on background queue
                                 if ([type isEqualToString:@"content"])
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPContentServiceFoundNotification"
                                                                                             object:self
                                                                                           userInfo:@{ @"name" : name,
                                                                                                       @"serviceId" : serviceId }];
                                     });
                             } withErrorResponder:^(NSString *errorString, ISPRequest *request) {
                                 NSLog(@"getServiceInformation errorString: %@", errorString);
                             }];
    
}

+ (void)accessTokenAcquired:(NSNotification *)notification {
    for (NSString * key in _allDevices) {
        ISPDevice * aDevice = [_allDevices objectForKey:key];
        if (!aDevice.known)
            [aDevice checkAccount];
    }
}



- (NSString *)name {
    if (_name)
        return _name;
    return self.defaultName;
}

- (BOOL)validated {
    return self.known;
}

- (void)dealloc {
    [[self class] removeFromDeviceList:self];
    //[_allDevices removeObjectForKey:DEVICE_UUID(_uuid, _ickType)];
}

- (void)configureWithURLString:(const char *)cURLString {
    NSLog(@"device:%@ url added: %s", self.uuid, cURLString);
    _url = [NSURL URLWithString:[NSString stringWithUTF8String:cURLString]];
}

- (NSURL *)url {
    //char * cUrl = ickP2pGetDeviceLocation([ISPDevice ickP2pContext], [_uuid UTF8String]);
    //if (!cUrl)
    //    return nil;
    //return [NSURL URLWithString:[NSString stringWithUTF8String:cUrl]];
    return [_url absoluteURL];      // don't use baseURL since that's usually empty
}

- (NSString *)displayName {
    if (_name)
        return _name;
    if (_defaultName)
        return _defaultName;
    return _uuid;
}

// when we support local services, they get in here...
- (NSURL *)urlForService:(NSString *)serviceId {
    if (!serviceId)
        return self.url;
    NSMutableDictionary __block * aService = nil;
    dispatch_sync_safe(dispatch_get_main_queue(), ^{
        aService = (NSMutableDictionary *)[_services dictionaryForKey:serviceId];
    });
    if (!aService) {
        serviceId = [[serviceId componentsSeparatedByString:@":"] objectAtIndex:0];
        aService = (NSMutableDictionary *)[_services dictionaryForKey:serviceId];
        if (!aService)
            return nil;
    }

    id sUrl = [aService objectForKey:@"url"]; //"url"
    if (!sUrl)
        sUrl = aService[@"serviceUrl"];
    if ([sUrl isKindOfClass:[NSURL class]])
        return sUrl;
    if (![sUrl isKindOfClass:[NSString class]])
        return nil;
    // next time we use the url it will already be an NSURL
    NSURL * rUrl = [NSURL URLWithString:sUrl];
    [aService setValue:rUrl forKey:@"url"];
    return rUrl;
}

+ (void)registerService:(NSString *)aServiceId ofType:(NSString *)serviceType forDevice:(ISPDevice *)aDevice {
    if (!aServiceId)
        return;
    [_allServices addObject:@{@"id" : aServiceId, @"type" : serviceType, @"device" : DEVICE_UUID(aDevice.uuid, aDevice.ickType)}];
}

+ (ISPDevice *)findDeviceWithServiceId:(NSString *)serviceId {
    if (!serviceId)
        return nil;
    
    if (!_allServices.count)
        return nil;
    NSArray * arr = [_allServices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", serviceId]];
    if (arr.count)
        return _allDevices[arr[0][@"device"]];
    return nil;
}

+ (NSString *)findServicesOfType:(NSString *)type {
    if (!type)
        return nil;
    
    NSArray * arr = [_allServices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
    if (arr.count)
        return [arr valueForKeyPath:@"id"];
    return nil;
}

+ (NSString *)findPreferredServiceOfType:(NSString *)type {
    if (!type)
        return nil;
    
    NSArray * arr = [_allServices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
    switch (arr.count) {
        case 0:
            return nil;
            break;
        case 1:
            return arr[0][@"id"];
            break;
        default: {
            ISPDeviceCloud * cloud = [ISPDeviceCloud singleton];
            NSString * did = DEVICE_UUID(cloud.uuid, cloud.ickType);
            NSArray * pref = [arr filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"device == %@", did]];
            if (pref.count)
                return pref[0][@"id"];
            return arr[0][@"id"];
        }
            break;
    }
    if (arr.count) {
    }
        return [arr valueForKeyPath:@"id"];
    return nil;
}

+ (NSArray *)allServices {
    return [_allServices valueForKeyPath:@"id"];
}

- (Class)atomicRequestClass {
    return [[self class] atomicRequestClass];
}

+ (Class)atomicRequestClass {
    return [ISPRWebsocketRequest class];
}

- (NSObject<ISPAtomicRequestProtocol> *)atomicRequestForService:(NSString *)aServiceId owner:(ISPRequest *)owner {
    NSObject<ISPAtomicRequestProtocol> * request = [[ISPRWebsocketRequest alloc] initWithOwner:owner andDevice:self];
    return request;
}

#pragma mark - message handling

- (void)handleDeviceNotification:(NSString *)method params:(NSDictionary *)params {
    
}



@end
