//
//  ISPRWebsocketRequest.h
//  ickComm
//
//  Created by Jörg Schwieder on 21.05.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "ISPRequest.h"

@interface ISPRWebsocketRequest : NSObject<ISPAtomicRequestProtocol>

@property (weak, nonatomic) ISPRequest * owner;
+ (void)registerCallback;

@end
