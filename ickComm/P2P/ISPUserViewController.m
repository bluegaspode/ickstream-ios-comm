//
//  ISPUserViewController.m
//  ickComm
//
//  Created by Jörg Schwieder on 03.06.12.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "ISPUserViewController.h"

@interface ISPUserViewController () {
    BOOL showAlert;
}


@property (weak, nonatomic) id delegate;

@end

@implementation ISPUserViewController

@synthesize tokenEntry;
@synthesize alert;
@synthesize delegate;

- (id)initWithDelegate:(id<ISPUserTokenDelegateProtocol>)aDelegate
{
    self = [super initWithNibName:@"ISPUserViewController" bundle:nil];
    if (self) {
        self.delegate = aDelegate;
        showAlert = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (showAlert)
        self.alert.hidden = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)dismissMe:(id)sender {
    if (delegate)
        [delegate hasEnteredToken:tokenEntry.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showAlert {
    self.alert.hidden = NO;
    showAlert = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tokenEntry resignFirstResponder];
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

@end
