//
//  ISPSpinner.m
//  ickStreamProto
//
//  Created by Jörg Schwieder on 29.05.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#import "ISPSpinner.h"

@interface ISPSpinner ()

@end

static __strong ISPSpinner * _singleton = nil;

@implementation ISPSpinner

- (id)init
{
    if (_singleton) {
        self = nil;
        self = _singleton;
        return self;
    }
    NSBundle *ickCommBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ickComm Bundle" withExtension:@"bundle"]];

    self = [super initWithNibName:@"ISPSpinner" bundle:ickCommBundle];
    if (self) {
        // Custom initialization
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.view.hidden = YES;
        self.view.alpha = 0;
        [[[UIApplication sharedApplication] keyWindow] addSubview:self.view];
    }
    return self;
}

+ (ISPSpinner *)sharedSpinner {
    if (!_singleton)
        _singleton = [[self alloc] init];
    return _singleton;
}
 
+ (void)showSpinnerAnimated:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        ISPSpinner * spinner = [self sharedSpinner];
        spinner.view.hidden = NO;
        [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:spinner.view];
        if (!animated)
            spinner.view.alpha = 1.0;
        else
            [UIView animateWithDuration:0.3 animations:^{
                spinner.view.alpha = 1.0;
            }];
    });
}

- (void)_hide {
    self.view.hidden = YES;
}

+ (void)hideSpinnerAnimated:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        ISPSpinner * spinner = [self sharedSpinner];
        if (animated)
            [UIView animateWithDuration:0.3 animations:^{
                spinner.view.alpha = 0.0;
                [spinner performSelector:@selector(_hide) withObject:nil afterDelay:0.3];
            }];
        else {
            spinner.view.alpha = 0.0;
            spinner.view.hidden = YES;
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}*/

@end
