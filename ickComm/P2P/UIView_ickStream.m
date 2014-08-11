//
//  UIView_ickStream.m
//  ickComm
//
//  Created by Jörg Schwieder on 23.10.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "UIView_ickStream.h"

@implementation UIView(ickStream)

- (UIView *)findSubviewOfClass:(Class)aClass {
    if ([self isKindOfClass:aClass])
        return self;
    for (UIView * aView in self.subviews) {
        if ([aView isKindOfClass:aClass])
            return aView;
        UIView * retView = [aView findSubviewOfClass:aClass];
        if ([retView isKindOfClass:aClass])
            return retView;
    }
    return nil;
}


@end
