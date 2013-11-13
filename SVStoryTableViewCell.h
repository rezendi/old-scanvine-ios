//
//  SVStoryTableViewCell.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVStory.h"
#import "SVMasterViewController.h"

@interface SVStoryTableViewCell : UITableViewCell <UIActionSheetDelegate>

@property (weak, nonatomic) SVMasterViewController *caller;
@property (strong, nonatomic) SVStory *story;
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) UIView *line;
@property (strong, nonatomic) UIButton *art;
@property (strong, nonatomic) UIButton *save;
@property (strong, nonatomic) UIButton *cached;
@property (strong, nonatomic) UIButton *share;
@property (strong, nonatomic) UILabel *title;
@property (strong, nonatomic) UILabel *blurb;
@property (strong, nonatomic) UILabel *byline;
@property (strong, nonatomic) NSString *clustered;
@property (strong, nonatomic) UIActivityIndicatorView *saveLoading;
@property (strong, nonatomic) UIActivityIndicatorView *shareLoading;

-(void)configureForStory:(SVStory*) story;

@end
