//
//  ISPRHttpRequest.h
//  ickComm
//
//  Created by Jörg Schwieder on 15.05.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ISPRequest.h"

@interface ISPRHttpRequest : NSMutableURLRequest<NSURLConnectionDelegate, ISPAtomicRequestProtocol>

@property (weak, nonatomic) ISPRequest * owner;

@end
