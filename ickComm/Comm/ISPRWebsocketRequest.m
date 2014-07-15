//
//  ISPRWebsocketRequest.m
//  ickStreamProto
//
//  Created by Jörg Schwieder on 21.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPRWebsocketRequest.h"
#import "ISPDevice.h"
#import "NSDictionary_ickStream.h"


@interface ISPRWebsocketRequest () {
	BOOL busy;
    __strong NSData * _body;
}

@property (weak, nonatomic) ISPDevice * device;

- (void)cleanup;

@end



@implementation ISPRWebsocketRequest

static void gotAMessage(ickP2pContext_t *ictx,
                        const char * sourceUUID,
                        ickP2pServicetype_t sourceService,
                        ickP2pServicetype_t targetServices,
                        const char * message,
                        size_t message_size,
                        ickP2pMessageFlag_t mFlags ) {
    // no valid incoming data? bye...
    //if (state != ICKMESSAGE_INCOMING_DATA)
    //    return;

    // not for us? bye...
    if (!(targetServices & ICKP2P_SERVICE_CONTROLLER))
        return;

    // logging... eventually remove!
    char * IP = ickP2pGetDeviceLocation(ictx, sourceUUID);
    //NSString * string = [NSString stringWithCString:message encoding:NSUTF8StringEncoding];
    //NSLog(@"\nMessage received: IP: %s, message:\n%s\n%s\n", IP, message,nil);//string
    
    //NSData * messageData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (message_size && (message[message_size - 1] == '\0'))
        message_size--;
    NSData * messageData = [NSData dataWithBytes:message length:message_size];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError * error;
        id reply = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingMutableContainers error:&error];
        if (error!=nil) {
            NSLog(@"error deserializing message from server: %@", error);
        }


        dispatch_async(dispatch_get_main_queue(), ^{

            /*if ([[UIDevice currentDevice] isIOS5]) {
             reply = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:message length:message_size] options:NSJSONReadingMutableContainers error:nil];
             } else {
             replyStr = [[NSString alloc] initWithUTF8String:message];
             reply = [replyStr JSONValue];
             }*/

            if(![reply isKindOfClass: [NSDictionary class]]) {
                // no idea how to react... we don't know what request this belongs to...
                return;
            }
            NSDictionary * replyDict = reply;
            id rId = [replyDict numericalForKey:@"id"];
            if (rId) {
                NSUInteger iId = 0;
                if ([rId respondsToSelector:@selector(unsignedIntValue)])
                    iId = [rId unsignedIntValue];
                else
                    iId = [rId intValue];

                ISPRequest * request = [ISPRequest requestForId:iId];
                if (request)
                    [request didReceiveResponse:replyDict];
            } else {
                // this means we are seeing a notification
                NSString * uuidStr = [NSString stringWithUTF8String:sourceUUID];
                ISPDevice * device = [ISPDevice findDeviceWithUUID:uuidStr andType:ickP2pGetDeviceServices(ictx, sourceUUID)];
                [device handleDeviceNotification:[replyDict stringForKey:@"method"]
                                          params:[replyDict dictionaryForKey:@"params"]];
            }

        });
    });
    
}

+ (void)registerCallback {
    ickP2pRegisterMessageCallback([ISPDevice ickP2pContext], &gotAMessage);
}

+ (void)initialize {
}

- (void)dealloc {
    [self cancel];
	[self cleanup];
    _body = nil;
}

- (id)initWithOwner:(ISPRequest *)anOwner andDevice:(ISPDevice *)aDevice {
    self = [super init];
    if (self) {
        self.owner = anOwner;
        self.device = aDevice;
        busy = NO;
    }
    return self;
}


- (void)cleanup {
    busy = NO;
}

- (void)cancel {
    // nothing to cancel...
}

- (BOOL)isBusy {
    return busy;
}


- (void)evaluateConnectionError {
}

- (void)setBody:(NSData *)body {
    _body = body;
}

- (void)call {
    [self cleanup];	
	busy = YES;
	
    // Send to known device type but never send to controllers.
    /*ickErrcode_t result = ickDeviceSendTargetedMsg([_device.uuid UTF8String],
                                                                     [_body bytes],
                                                                     [_body length],
                                                                     _device.ickType & ~ICKP2P_SERVICE_CONTROLLER,
                                                                     NULL);*/
    
    ickErrcode_t error = ickP2pSendMsg([ISPDevice ickP2pContext],
                                       _device.uuid.UTF8String,
                                       _device.ickType & ~ICKP2P_SERVICE_CONTROLLER,
                                       ICKP2P_SERVICE_CONTROLLER,
                                       _body.bytes,
                                       _body.length);
    
    if (error != ICKERR_SUCCESS) {
		[self evaluateConnectionError];

        dispatch_async(dispatch_get_main_queue(), ^{
            [_owner didReceiveError:[NSString stringWithFormat:@"[CONN] Cannot send request. Error %d", error]];
        });
    }    
}


@end
