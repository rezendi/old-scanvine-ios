//
//  SVViewController.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-22.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVViewController.h"

@interface SVViewController ()

@end

@implementation SVViewController

-(void)showLoading {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = barButton;
    [activityIndicator startAnimating];
}

-(void)stopLoading {
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)showOptions {
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"options"] style:UIBarButtonItemStyleBordered target:self action:@selector(options:)];
    self.navigationItem.rightBarButtonItem = optionsButton;
}

-(void)options:(id)sender {
    
}
@end
