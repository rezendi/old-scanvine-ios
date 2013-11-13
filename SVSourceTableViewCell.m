//
//  SVSourceTableViewCell.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-22.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVSourceTableViewCell.h"

@implementation SVSourceTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
