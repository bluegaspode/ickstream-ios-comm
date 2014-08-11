//
//  ISPSpinner.h
//  ickComm
//
//  Created by Jörg Schwieder on 29.05.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISPSpinner : UIViewController

+ (ISPSpinner *)sharedSpinner;
+ (void)showSpinnerAnimated:(BOOL)animated;
+ (void)hideSpinnerAnimated:(BOOL)animated;

@end
