//
//  ISPUserViewController.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 03.06.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ISPUserTokenDelegateProtocol

- (void)hasEnteredToken:(NSString *)token;

@end



@interface ISPUserViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField * tokenEntry;
@property (strong, nonatomic) IBOutlet UILabel * alert;

- (id)initWithDelegate:(id<ISPUserTokenDelegateProtocol>)aDelegate;
- (void)showAlert;

@end
