//
//  ISPRequest.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 11.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//
//  JSONRPCRequest handles a JSON/RPC Request to a service or a device.
//  This handles requests to devices and local services as well as requests to the Cloud service
//  However, the actual execution is very different between the targets
//
//  Device (this includes services on local network being registered through a device)
//  Communication: The request will be sent through the existing websocket connection to the device
//  Parameters:
//  serviceId:      The prefix of the service to be targeted, or NULL for device communication (e.g. with a player or controller)
//  targetDevice:   The device the request is to be sent to. Mandatory for devices.
//
//  Cloud Service
//  Communication: and http request will be sent to the cloud service
//  Parameters:
//  serviceId:      The prefix for the service the request goes to. Mandatory for cloud services
//  targetDevice:   NULL or the ISPDeviceCloud singleton.
//

#import <Foundation/Foundation.h>

@class ISPDevice;

@interface ISPRequest : NSObject


@property (strong, nonatomic) NSString *    serviceId;
@property (weak, nonatomic) ISPDevice *     targetDevice;
@property (nonatomic) BOOL busy;
@property (nonatomic) BOOL cancelled;
@property (weak, nonatomic, readonly) id target;
@property (nonatomic) BOOL notificationOnly;
@property (strong, nonatomic, readonly) NSNumber * requestId;
@property (nonatomic) NSRange range;

@property (copy, nonatomic) void (^responseBlock)(NSDictionary *,  ISPRequest *);
@property (copy, nonatomic) void (^errorBlock)(NSString *, ISPRequest *);

// fragment can bei either a dictionary (the id and protocol will be added) containing params and method.
// or it can be a string. If it's a string it's expected to be fully encoded.
// A string request will NOT be id matched, a synchronous http request might still be reply matched but this only applies to cloud services
// device requests (both to services and devices) will NOT get a reply so they will be configured as notifications and immediately freed after sending if they are nonpersistant.
- (id)initWithDevice:(ISPDevice *)device andService:(NSString *)service andJSONFragment:(id)fragment persistant:(BOOL)isPersistant;
- (id)initWithDevice:(ISPDevice *)device andService:(NSString *)service andJSONFragment:(id)fragment persistant:(BOOL)isPersistant
       withResponder:(void(^)(NSDictionary *, ISPRequest *))aReply withErrorResponder:(void(^)(NSString *, ISPRequest *))anErrorReply;
+ (id)requestWithDevice:(ISPDevice *)device andService:(NSString *)service andJSONFragment:(id)fragment;
+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)device andService:(NSString *)service andJSONFragment:(id)fragment;
+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)device andService:(NSString *)service andJSONFragment:(id)fragment
                             withResponder:(void(^)(NSDictionary * result,  ISPRequest * request))aReply
                        withErrorResponder:(void(^)(NSString * errorString, ISPRequest * request))anErrorReply;
+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)device service:(NSString *)service method:(NSString *)method params:(NSDictionary *)params;
+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)device service:(NSString *)service method:(NSString *)method params:(NSDictionary *)params
                             withResponder:(void(^)(NSDictionary * result,  ISPRequest * request))aReply
                        withErrorResponder:(void(^)(NSString * errorString, ISPRequest * request))anErrorReply;

// The target needs to be set before calling the request or it will be ignored!
- (void)setTarget:(id)target withSelector:(SEL)action withErrorSelector:(SEL)errorAction;
- (void)setRange:(NSRange)range;
- (void)call;

- (void)cancel;
+ (void)collect_garbage;
//+ (void)cancelGarbage:(id)target;
+ (void)addToHeap:(ISPRequest *)me;
- (void)addToHeap;

+ (NSUInteger)newRequestId;

// real entries...
- (void)didReceiveError:(NSString *)errorText;
- (void)didReceiveResponse:(NSDictionary *)response;

- (NSData *)constructBody;

+ (ISPRequest *)requestForId:(NSUInteger)anId;
+ (void)removeRequestWithId:(NSUInteger)anId;

@end


@protocol ISPAtomicRequestProtocol <NSObject>

- (void)evaluateConnectionError;
- (id)initWithOwner:(ISPRequest *)anOwner andDevice:(ISPDevice *)aDevice;
- (void)setBody:(NSData *)body;
- (void)call;
- (void)cancel;
- (BOOL)isBusy;

@end
