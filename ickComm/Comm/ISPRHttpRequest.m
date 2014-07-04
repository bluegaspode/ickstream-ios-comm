//
//  ISPRHttpRequest.m
//  ickStreamProto
//
//  Created by Jörg Schwieder on 15.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPRHttpRequest.h"
#import "ISPDevice.h"

@interface ISPRHttpRequest () {
	BOOL busy;
}

@property (strong, nonatomic) NSURLConnection * mConnection;
@property (strong, nonatomic) NSMutableData * mReplyBody;
@property (strong, nonatomic) NSURLAuthenticationChallenge * mChallenge;

- (void)cleanup;

@end

@implementation ISPRHttpRequest

@synthesize owner = _owner;
@synthesize mConnection = _mConnection;
@synthesize mReplyBody = _mReplyBody;
@synthesize mChallenge = _mChallenge;

- (void)dealloc {
    [self cancel];
    self.mConnection = nil;
    self.mReplyBody = nil;
    self.mChallenge = nil;
	[self cleanup];
}

- (id)initWithOwner:(ISPRequest *)anOwner andDevice:(ISPDevice *)aDevice {
    self = [super initWithURL:[aDevice urlForService:[anOwner serviceId]]];
    if (self) {
        self.owner = anOwner;
        [self setHTTPMethod:@"POST"];
        busy = NO;
    }
    return self;
}


- (void)setBody:(NSData *)body {
    [self setHTTPBody:body];
}

- (void)call {
    [self cleanup];
	
	busy = YES;
	
	self.mReplyBody = [NSMutableData data];
    
    dispatch_async(dispatch_get_main_queue(), ^{        
        // requires main run loop        
        self.mConnection = [[NSURLConnection alloc] initWithRequest:self delegate:self];
        if(!_mConnection) {
            [self evaluateConnectionError];
            [_owner didReceiveError:@"[CONN] Cannot connect to server."];
        }
    });
}

- (void)cancel {
    if (_mConnection)
		[_mConnection cancel];
}

- (void)cleanup {
    busy = NO;
	if(_mReplyBody)
		self.mReplyBody = nil;
    
	if(_mConnection)
		self.mConnection = nil;
}

- (BOOL)isBusy {
    return busy;
}

#pragma mark - response handling, NSURLConnectionDelegate protocol

- (void)evaluateConnectionError {
    
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return self;
}

- (void)connection:(NSURLConnection*)connection didFailWithError: (NSError*)error {
    [self evaluateConnectionError];
    [_owner didReceiveError:@"[CONN] Connect error."];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse: (NSURLResponse*)response {
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	
	NSInteger code = [httpResponse statusCode];
	if(code != 200) {
        [self evaluateConnectionError];
        [_owner didReceiveError:[NSString stringWithFormat:@"[CONN] Connect error, code %d.", [httpResponse statusCode]]];
	}
	
	[_mReplyBody setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData: (NSData*)data {
	[_mReplyBody appendData:data];
}

- (void)connectionDidFinishLoading: (NSURLConnection*)connection {
    id reply = nil;
    NSString * replyStr = nil;
    reply = [NSJSONSerialization JSONObjectWithData:_mReplyBody options:NSJSONReadingMutableContainers error:nil];

    NSLog(@"data: \n###%@###", [[NSString alloc] initWithData:_mReplyBody encoding: NSUTF8StringEncoding]);

	if(![reply isKindOfClass: [NSDictionary class]]) {
        if (!replyStr)
            replyStr = [[NSString alloc] initWithData:_mReplyBody encoding: NSUTF8StringEncoding];            
        [_owner didReceiveError:[NSString stringWithFormat:@"[CONN] Unexpected response '%@'.", replyStr]];
        self.mReplyBody = nil;
		return;
	}
    self.mReplyBody = nil;
    [_owner didReceiveResponse:reply];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"authorizationChallenge");
}






@end
