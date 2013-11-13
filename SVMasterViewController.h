//
//  SVMasterViewController.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVViewController.h"

@class SVDisplayViewController;

@interface SVMasterViewController : SVViewController <UIActionSheetDelegate>

@property (strong, nonatomic) NSDictionary *json;
@property (strong, nonatomic) NSArray *stories;
@property (strong, nonatomic) NSString *time;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSDictionary *author;
@property (strong, nonatomic) NSDictionary *source;
@property (strong, nonatomic) NSNumber *downloads;

-(void)reloadCellFor:(id)story;

@end
