//
//  SVDisplayViewController.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVViewController.h"
#import "SVStory.h"

@interface SVDisplayViewController : UIViewController <UISplitViewControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate>;

@property (strong, nonatomic) SVStory *story;
@property (strong, nonatomic) UIWebView *webView;

@end
