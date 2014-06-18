//
//  ISPSpinner.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 29.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISPSpinner : UIViewController

+ (ISPSpinner *)sharedSpinner;
+ (void)showSpinnerAnimated:(BOOL)animated;
+ (void)hideSpinnerAnimated:(BOOL)animated;

@end
