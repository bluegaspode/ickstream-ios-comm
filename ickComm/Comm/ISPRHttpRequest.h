//
//  ISPRHttpRequest.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 15.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ISPRequest.h"

@interface ISPRHttpRequest : NSMutableURLRequest<NSURLConnectionDelegate, ISPAtomicRequestProtocol>

@property (weak, nonatomic) ISPRequest * owner;

@end
