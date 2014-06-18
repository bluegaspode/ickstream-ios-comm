//
//  ISPRequest.m
//  ickStreamProto
//
//  Created by Jörg Schwieder on 11.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPRequest.h"
#import "ISPDevice.h"


@interface ISPRequest() {
    BOOL                _persist;
    __weak id           _mTarget;
    SEL                 _mAction;
    SEL                 _mErrorAction;
}

@property (strong, nonatomic) id fragment;
@property (strong, nonatomic) NSObject<ISPAtomicRequestProtocol> * atomicRequest;
@property (strong, nonatomic, readwrite) NSNumber * requestId;

- (void)collect;
- (void)cleanup;
/*
NSString * JSONString;

BOOL persist;
BOOL busy;
id mTarget;
SEL mAction;
SEL mErrorAction;
BOOL cancelled;
NSURLAuthenticationChallenge *mChallenge;*/

@end



static __strong NSMutableArray * _garbage = nil;

static __strong NSMutableDictionary * _allRequests = nil;
static dispatch_queue_t _allRequestQueue;


@implementation ISPRequest

@synthesize busy =_busy;
@synthesize cancelled = _cancelled;
@synthesize fragment=_fragment;
@synthesize targetDevice=_targetDevice;
@synthesize serviceId=_serviceId;
@synthesize target=_mTarget;
@synthesize errorBlock=_errorBlock;
@synthesize responseBlock=_responseBlock;
@synthesize atomicRequest=_atomicRequest;
@synthesize requestId=_requestId;
@synthesize notificationOnly=_notificationOnly;
@synthesize range=_range;


#pragma mark - heap management

- (void)dealloc {
	_cancelled = YES;
	[self cleanup];
}

+ (void)collect_garbage {
    // releaase all - this is a bit brute. Could become more refined by releasing all that are above a certain timeout.
	[_garbage removeAllObjects];
}

+ (void)addToHeap:(ISPRequest *)me {
	if (!me) return;
	[_garbage addObject:me];
}

- (void)addToHeap {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_garbage addObject:self];
    });
}

- (void)collect {
	if (!_persist) {
        dispatch_sync_safe(dispatch_get_main_queue(), ^{
            [_garbage removeObject:self];
        });
		_persist = YES;
	} else
		[self cleanup];
}

- (void)cleanup {
	self.busy = NO;
    dispatch_sync(_allRequestQueue, ^{
        if (_requestId)
            [_allRequests removeObjectForKey:_requestId];
        self.requestId = nil;
    });
}


#pragma mark - initialization

+ (void)initialize {
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _garbage = [[NSMutableArray alloc] initWithCapacity:20];
        _allRequests = [[NSMutableDictionary alloc] initWithCapacity:20];
        _allRequestQueue = dispatch_queue_create("com.ickStream.requestQueue", 0);
    });
}

// make sure both fragement and params are mutable if fragment is a dict
- (void)_setDictionaryFragment:(NSDictionary *)fragment {
    NSMutableDictionary * dict = [fragment mutableCopy];
    [dict setValue:@"2.0" forKey:@"jsonrpc"];
    NSDictionary * params = [fragment dictionaryForKey:@"params"];
    if (params)
        [dict setObject:[params mutableCopy] forKey:@"params"];
    self.fragment = dict;
}


- (id)initWithDevice:(ISPDevice *)deviceId andService:(NSString *)service andJSONFragment:(NSDictionary *)afragment persistant:(BOOL)isPersistant {
    self = [super init];
    if (self) {
        _cancelled = NO;
        _busy = NO;
        // Dicts will always be mutable
        if ([afragment isKindOfClass:[NSDictionary class]])
            [self _setDictionaryFragment:afragment];
        else
            self.fragment = afragment;
		_persist = isPersistant;
        self.serviceId = service;
        self.targetDevice = deviceId;
        _mTarget = nil;
        _range = NSMakeRange(0, 0);
		if (!_persist)
			[self addToHeap];
        self.responseBlock = nil;
        self.errorBlock = nil;
    }
    return self;
}

- (id)initWithDevice:(ISPDevice *)deviceId andService:(NSString *)service andJSONFragment:(id)afragment persistant:(BOOL)isPersistant 
       withResponder:(void(^)(NSDictionary *, ISPRequest *))aReply withErrorResponder:(void(^)(NSString *, ISPRequest *))anErrorReply {    
    self = [super init];
    if (self) {
        _cancelled = NO;
        _busy = NO;
        if ([afragment isKindOfClass:[NSDictionary class]])
            [self _setDictionaryFragment:afragment];
        else
            self.fragment = afragment;
		_persist = isPersistant;
        self.serviceId = service;
        self.targetDevice = deviceId;
        _range = NSMakeRange(0, 0);
        _mTarget = nil;
		if (!_persist)
			[self addToHeap];
        self.responseBlock = aReply;
        self.errorBlock = anErrorReply;
    }
    return self;
}

#pragma mark - helper functions for quick request generation

+ (id)requestWithDevice:(ISPDevice *)deviceId andService:(NSString *)service andJSONFragment:(id)fragment {
    return [[ISPRequest alloc] initWithDevice:deviceId andService:service andJSONFragment:fragment persistant:NO];
}

+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)deviceId andService:(NSString *)service andJSONFragment:(id)fragment {
    ISPRequest * request = [[ISPRequest alloc] initWithDevice:deviceId andService:service andJSONFragment:fragment persistant:NO];
    [request call];
    return request;
}

+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)deviceId andService:(NSString *)service andJSONFragment:(id)fragment 
                     withResponder:(void(^)(NSDictionary *, ISPRequest *))aReply withErrorResponder:(void(^)(NSString *, ISPRequest *))anErrorReply {
    ISPRequest * request = [[ISPRequest alloc] initWithDevice:deviceId andService:service andJSONFragment:fragment persistant:NO withResponder:aReply withErrorResponder:anErrorReply];
    [request call];
    return request;
}

+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)deviceId service:(NSString *)service method:(NSString *)method params:(NSDictionary *)params {
    if (!params)
        params = [NSMutableDictionary dictionary];
    NSMutableDictionary * fragment = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      method, @"method",
                                      params, @"params", nil];
    ISPRequest * request = [[ISPRequest alloc] initWithDevice:deviceId andService:service andJSONFragment:fragment persistant:NO];
    [request call];
    return request;    
}

+ (ISPRequest *)automaticRequestWithDevice:(ISPDevice *)deviceId service:(NSString *)service method:(NSString *)method params:(NSDictionary *)params
                             withResponder:(void(^)(NSDictionary * result,  ISPRequest * request))aReply
                        withErrorResponder:(void(^)(NSString * errorString, ISPRequest * request))anErrorReply {
    if (!params)
        params = [NSMutableDictionary dictionary];
    NSMutableDictionary * fragment = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      method, @"method",
                                      params, @"params", nil];
    ISPRequest * request = [[ISPRequest alloc] initWithDevice:deviceId andService:service andJSONFragment:fragment persistant:NO withResponder:aReply withErrorResponder:anErrorReply];
    [request call];
    return request;        
}


#pragma mark - request handling

- (void)setTarget:(id)target withSelector:(SEL)action withErrorSelector:(SEL)errorAction {
	_mTarget = target;
	_mAction = action;
	_mErrorAction = errorAction;
}


+ (NSUInteger)newRequestId {    
    static NSUInteger _anId = 2;
    
    __block NSUInteger myId;
    
    dispatch_sync(_allRequestQueue, ^{
        myId = _anId;
        _anId++;
    });
    return myId;
}

+ (ISPRequest *)requestForId:(NSUInteger)anId {
    return [_allRequests objectForKey:[NSNumber numberWithUnsignedInt:anId]];
}

+ (void)removeRequestWithId:(NSUInteger)anId {
    dispatch_sync(_allRequestQueue, ^{
        [_allRequests removeObjectForKey:[NSNumber numberWithUnsignedInt:anId]];
    });
}

- (NSData *)constructBody {
    if (!_fragment)
        return nil;
    if ([_fragment isKindOfClass:[NSString class]])
        return [(NSString *)_fragment dataUsingEncoding:NSUTF8StringEncoding];
    if (![_fragment isKindOfClass:[NSDictionary class]])
        return nil;
    // Dicts are always mutable
    NSMutableDictionary * dict = (NSMutableDictionary *)_fragment;
    
    self.requestId = [NSNumber numberWithUnsignedInt:[ISPRequest newRequestId]];
    [dict setValue:_requestId forKey:@"id"];
    
    dispatch_sync(_allRequestQueue, ^{
        if ((_mTarget || _responseBlock) && self && _requestId)
            [_allRequests setObject:self forKey:_requestId];
    });
    NSLog(@"%@", dict);
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
}

- (void)setRange:(NSRange)range {
    _range = range;
    if (![_fragment isKindOfClass:[NSDictionary class]])
        return;
    NSMutableDictionary * dict = (NSMutableDictionary *)_fragment;
    NSMutableDictionary * params = (NSMutableDictionary *)[dict dictionaryForKey:@"params"];
    [params setObject:[NSNumber numberWithInt:range.location] forKey:@"offset"];
    [params setObject:[NSNumber numberWithInt:range.length] forKey:@"count"];
}

- (void)call {
    static dispatch_queue_t _call_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _call_queue = dispatch_queue_create("com.ickStream.requestCallQueue", 0);
    });
    
    dispatch_async(_call_queue, ^{
        [self cleanup];
        
        _cancelled = NO;
        self.busy = YES;
        NSData* body = [self constructBody];
        if (!_targetDevice && _serviceId)
            _targetDevice = [ISPDevice findDeviceWithServiceId:_serviceId];
        if (!_targetDevice && !_serviceId)
            return;
        self.atomicRequest = [_targetDevice atomicRequestForService:_serviceId owner:self];
        [_atomicRequest setBody:body];
        [_atomicRequest call];
    });
}

- (void)cancel {
    [_atomicRequest cancel];
    _cancelled = YES;
}

#pragma mark - responder entries

- (void)didReceiveError:(NSString *)errorText {
    if (_errorBlock && !_cancelled)
        _errorBlock(errorText, self);
    else if (_mTarget && !_cancelled && _mErrorAction && [_mTarget respondsToSelector:_mErrorAction])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_mTarget performSelector:_mErrorAction withObject:errorText withObject:self];
#pragma clang diagnostic pop
    [self collect];
}

- (void)didReceiveResponse:(NSDictionary *)response {
    if (!response) {
        [self didReceiveError:@"[CONN] no valid response"];
        return;
    }
    
    id error = [response objectForKey:@"error"];
    if (error && (error != [NSNull null])) {
        [self didReceiveError:[NSString stringWithFormat:@"[CONN] Unexpected response '%@'.", error]];
        [self collect];
        return;
    }
    // only use response block, can get the id from self
    // saves us a line of code in every response handler
    // and I REALLY want a dictionary as the result!
    id result = [response objectForKey:@"result"];
    if ([result isKindOfClass:[NSDictionary class]])
        response = result;
    else if ([result isKindOfClass:[NSArray class]])
        response = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    result, @"items",
                    [NSNumber numberWithInt:[result count]], @"count",
                    nil];
    else if ([result isKindOfClass:[NSValue class]]) {
        response = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    result, @"value",
                    nil];        
    } else if ([result isKindOfClass:[NSString class]]) {
        response = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    result, @"text",
                    nil];
    } else // don't allow anything else
        response = nil;    
    //    response = [response dictionaryForKey:@"result"];
    
    if (_responseBlock  && !_cancelled)
        _responseBlock(response, self);
    else if (_mTarget  && !_cancelled && _mAction && [_mTarget respondsToSelector:_mAction])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_mTarget performSelector:_mAction withObject:response withObject:self];
#pragma clang diagnostic pop
    [self collect];
}



@end
