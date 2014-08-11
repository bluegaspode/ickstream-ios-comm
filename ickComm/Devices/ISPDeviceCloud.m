//
//  ISPDeviceCloud.m
//  ickComm
//
//  Created by Jörg Schwieder on 13.04.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//


#import "ISPDeviceCloud.h"
#import "ISPRHttpRequest.h"
#import "ISPRequest.h"
#import "ISPDeviceMyself.h"
#import "ISPSpinner.h"
#import "NSDictionary_ickStream.h"



NSString * const kDefaultCloudCoreURLString = @"https://api.ickstream.com/ickstream-cloud-core/";



static NSString * baseURLString = nil;
static NSURL * cloudCoreURL = nil;



@interface ISPDeviceCloud ()

//@property (strong, nonatomic) NSMutableDictionary * services;
//@property (strong, nonatomic) NSString * token;

@end

static __strong ISPDeviceCloud * _singleton;

@implementation ISPDeviceCloud

//@synthesize services = _services;

+ (void)initialize {
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        baseURLString = kDefaultCloudCoreURLString;
        _singleton = [[self alloc] init];
    });
   
}

+ (NSString *)applicationId {
    return @"Create Application ID!!";
}

+ (ISPDeviceCloud *)singleton {
    return _singleton;
}


#define REQUEST_RETRY_DELAY 1.0

- (void)getCloudServices {
    NSString * token = [ISPDeviceMyself myselfToken];
    if (!token) {
        //        [ISPSpinner showSpinnerAnimated:YES];
        [self performSelector:@selector(getCloudServices) withObject:nil afterDelay:REQUEST_RETRY_DELAY];
        return;
    }
    static BOOL triedToken = NO;
    
    ISPRequest * aRequest = [ISPRequest automaticRequestWithDevice:self service:nil method:@"findServices" params:nil withResponder:^(NSDictionary * result, ISPRequest * request) {
        //process result
        NSArray * allServices = [result objectForKey:@"items"];
        for (NSDictionary * service in allServices) {
            NSString * serviceId = service[@"id"];
            NSString * sId = [service stringForKey:@"type"];
            if (!sId) sId = @"";
            [self.services setValue:service forKey:serviceId];
            [ISPDevice registerService:serviceId ofType:sId forDevice:self];
                        
            // only content services have menus.
            if ([sId isEqualToString:@"content"])
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ISPContentServiceFoundNotification"
                                                                    object:self
                                                                  userInfo:@{ @"name" : [service stringForKey:@"name"],
                                                                              @"serviceId" : serviceId }];

        }
        triedToken = NO;
    } withErrorResponder:^(NSString * errorString, ISPRequest * request) {
        // process error
        NSLog(@"%@", errorString);
        
        if ([errorString isEqualToString:@"[CONN] Connect error, code 401."]) {
            // if we have a user token, first try to get authorization again (doesn't survive restart, so not likely)
            // if that fails: clear user token and ask for a new one
            if (triedToken && [ISPDeviceMyself myselfUserToken]) {
                [ISPDeviceMyself clearMyselfUserToken];
                [ISPDeviceMyself clearMyselfToken];
            } else {
                [ISPDeviceMyself clearMyselfToken];
                triedToken = YES;
            }
            [self performSelector:@selector(getCloudServices) withObject:nil afterDelay:REQUEST_RETRY_DELAY];
            return;            
        }
    }];
    aRequest = nil;
}

- (void)getDevicesForUser {
    ISPRequest * aRequest = [ISPRequest automaticRequestWithDevice:self service:nil method:@"findDevices" params:nil withResponder:^(NSDictionary * result, ISPRequest * request) {
        //process result
        NSArray * allServices = result[@"items"];
        for (NSDictionary * service in allServices) {
            NSString * serviceId = service[@"id"];
            [self.services setValue:service forKey:serviceId];
            NSString * type = service[@"type"];
            if (!type) type = @"";
            [ISPDevice registerService:serviceId ofType:service[@"type"] forDevice:self];
        }
    } withErrorResponder:^(NSString * errorString, ISPRequest * request) {
        // process error
        NSLog(@"%@", errorString);        
    }];
    aRequest = nil;
}


- (id)init {
    self = [super init];
    if (self) {
        self.uuid = nil;
        self.services = [[NSMutableDictionary alloc] initWithCapacity:5];
        [[self class] registerInDeviceList:self];
    }
    return self;
}


#pragma mark - cloud core URL

//  allow cloud core URL configuration.
// The actual configuration has to be done by the using App
// This defaults to the default cloud core URL

+ (void)setBaseCloudCoreURLString:(NSString *)urlString {
    if (urlString.length == 0) {
        baseURLString = kDefaultCloudCoreURLString;
    } else {
        if (![urlString hasSuffix:@"/"])
            urlString = [NSString stringWithFormat:@"%@/", urlString];
        baseURLString = urlString;
    }
}

+ (NSString *)baseCloudCoreURLString {
    return baseURLString;
}

- (NSURL *)url {
    if (!cloudCoreURL) {
        NSString * urlString = baseURLString;
        urlString = [NSString stringWithFormat:@"%@jsonrpc", urlString];
        
        cloudCoreURL = [NSURL URLWithString:urlString];
    }
    return cloudCoreURL;
}

- (NSString *)cloudURL {
    return cloudCoreURL.absoluteString;
}

#pragma mark - atomic request

- (NSObject<ISPAtomicRequestProtocol> *)atomicRequestForService:(NSString *)aServiceId owner:(ISPRequest *)owner {
    NSMutableURLRequest<ISPAtomicRequestProtocol> * request = [[ISPRHttpRequest alloc] initWithOwner:owner andDevice:self];
    NSString * authorizationString = [ISPDeviceMyself deviceAuthorization];
    NSLog(@"Authorization String: %@", authorizationString);
    [request addValue:authorizationString forHTTPHeaderField:@"Authorization"];
    return request;
}

+ (Class)atomicRequestClass {
    return [ISPRHttpRequest class];
}



@end
