//
//  ISPRWebsocketRequest.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 21.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPRequest.h"

@interface ISPRWebsocketRequest : NSObject<ISPAtomicRequestProtocol>

@property (weak, nonatomic) ISPRequest * owner;
+ (void)registerCallback;

@end
