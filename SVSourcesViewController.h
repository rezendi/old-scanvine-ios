//
//  SVSourcesViewController.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-22.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVViewController.h"

@interface SVSourcesViewController : SVViewController {
    BOOL sortByName;
}

@property (strong, nonatomic) NSDictionary *json;
@property (strong, nonatomic) NSArray *sources;

@end
