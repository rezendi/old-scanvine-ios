//
//  SVStoryTableViewCell.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVStoryTableViewCell.h"
#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@implementation SVStoryTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.opaque = YES;

        self.card = [[UIView alloc] initWithFrame:CGRectZero];
        self.card.opaque = YES;
        self.card.backgroundColor = [UIColor whiteColor];
        [self.card setAutoresizingMask:(UIViewAutoresizingFlexibleHeight)];

        self.title = [[UILabel alloc] initWithFrame:CGRectZero];
        self.title.opaque = YES;
        [self.title setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
        self.title.numberOfLines = 0;
        [self.title setTextColor:[UIColor blackColor]];
        [self.title setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [self.card addSubview:self.title];

        self.blurb = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.blurb setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        self.blurb.numberOfLines = 0;
        self.blurb.opaque = YES;
        self.blurb.hidden = YES;
        [self.card addSubview:self.blurb];

        self.art = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 50, 50)];
        self.art.opaque = YES;
        [self.art addTarget:self action:@selector(showBlurb:) forControlEvents:UIControlEventTouchUpInside];
        [self.card addSubview:self.art];

        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.opaque = YES;
        self.line.backgroundColor = [UIColor blackColor];
        [self.card addSubview:self.line];

        self.save = [UIButton buttonWithType:UIButtonTypeCustom];
        self.save.showsTouchWhenHighlighted = YES;
        [self.save setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        [self.save addTarget:self action:@selector(saveStory:) forControlEvents:UIControlEventTouchUpInside];
        [self.card addSubview:self.save];

        self.cached = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cached.showsTouchWhenHighlighted = YES;
        [self.cached setImage:[UIImage imageNamed:@"briefcase"] forState:UIControlStateNormal];
        [self.cached addTarget:self action:@selector(deleteStory:) forControlEvents:UIControlEventTouchUpInside];
        [self.card addSubview:self.cached];
        
        self.share = [UIButton buttonWithType:UIButtonTypeCustom];
        self.share.showsTouchWhenHighlighted = YES;
        [self.share setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
        [self.share addTarget:self action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
        [self.card addSubview:self.share];

        self.byline = [[UILabel alloc]  initWithFrame:CGRectZero];
        self.byline.opaque = YES;
        self.byline.numberOfLines = 0;
        [self.byline setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        [self.byline setTextColor:[UIColor blackColor]];
        [self.byline setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [self.card addSubview:self.byline];
    }
    return self;
}

- (void) configureForStory:(SVStory *)story {
    if (self.story)
        [self.story removeObserver:self forKeyPath:@"cached"];
    self.story = story;
    [self.story addObserver:self forKeyPath:@"cached" options:0 context:NULL];
}

- (void) layoutSubviews {
    [super layoutSubviews];

    self.backgroundColor = [UIColor lightGrayColor];
    
    CGSize size = self.contentView.frame.size;
    BOOL ind = [self.story isClustered];
    self.card.frame = CGRectMake(ind ? 24.0 : 6.0, 2.0, ind ? size.width-28.0 : size.width-12.0, size.height-4.0);
    [self.contentView addSubview:self.card];
    
    CALayer *layer = self.card.layer;
    [layer setCornerRadius:7.0f];
    
    [layer setBorderColor:[UIColor blackColor].CGColor];
    [layer setBorderWidth:1.0f];
    
    [layer setShadowColor:[UIColor grayColor].CGColor];
    [layer setShadowOpacity:1.0];
    [layer setShadowRadius:1.0];
    [layer setShadowOffset:CGSizeMake(1.0, 1.0)];
    
    [self loadImageForView:self.art forStory:self.story];
    
    size = self.card.frame.size;
    self.title.text = [self.story rankAndTitle];
    CGRect titleRect = [self.title.text boundingRectWithSize:CGSizeMake(size.width-70, 600)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:self.title.font}
                                                     context:nil];
    float titleHeight = titleRect.size.height > 50 ? titleRect.size.height : 50;
    self.title.frame = CGRectMake(65, 10, titleRect.size.width, titleHeight);
    [self.title sizeToFit];
    
    if (self.story.blurbed) {
        self.blurb.hidden = NO;
        self.blurb.text = [self.story blurb];
        CGRect blurbRect = [self.blurb.text boundingRectWithSize:CGSizeMake(size.width-70, 600)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:self.blurb.font}
                                                         context:nil];
        self.blurb.frame = CGRectMake(65, titleHeight+15, blurbRect.size.width, blurbRect.size.height);
        [self.blurb sizeToFit];
        titleHeight += blurbRect.size.height+10;
    }
    else
        self.blurb.hidden = YES;

    float lineHeight = titleHeight==50 ? 65 : titleHeight+15;
    self.line.frame =  CGRectMake(5, lineHeight, size.width-10, 1);
    
    self.byline.text = [self.story byline];
    CGRect bylineRect = [self.byline.text boundingRectWithSize:CGSizeMake(size.width-105, 600)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:self.byline.font}
                                                     context:nil];
    self.byline.frame = CGRectMake(10, lineHeight+12.5, bylineRect.size.width, bylineRect.size.height);

    self.save.hidden = YES;
    self.cached.hidden = YES;
    UIButton *saveButton = [self.story isCached] ? self.cached : self.save;
    saveButton.frame = CGRectMake(size.width-90, lineHeight+6, 44, 30);
    saveButton.hidden = NO;

    self.share.frame = CGRectMake(size.width-45, lineHeight+6, 44, 30);
    
    if ([self.story.caching boolValue]) {
        self.saveLoading = [[UIActivityIndicatorView alloc] initWithFrame:self.save.frame];
        self.saveLoading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self.card addSubview:self.saveLoading];
        [self.saveLoading startAnimating];
    }
    else if (self.saveLoading) {
        [self.saveLoading stopAnimating];
        [self.saveLoading removeFromSuperview];
        self.saveLoading = nil;
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

#pragma mark Business logic

- (void) showBlurb:(id)sender {
    self.story.blurbed = [self.story.blurbed boolValue] ? nil : [NSNumber numberWithBool:YES];
    [self.caller reloadCellFor:self.story];
}

- (void) saveStory:(id)sender {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Story Save"
                                                          action:self.story.url
                                                           label:self.story.title
                                                           value:nil] build]];

    self.story.caching = [NSNumber numberWithBool:YES];
    [self.story saveLocally];
    [self setNeedsLayout];
}

- (void) shareStory:(id)sender {
    self.shareLoading = [[UIActivityIndicatorView alloc] initWithFrame:self.share.frame];
    self.shareLoading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.card addSubview:self.shareLoading];
    [self.shareLoading startAnimating];
    [self performSelector:@selector(stopShareLoad:) withObject:nil afterDelay:1.0];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Story Share"
                                                          action:self.story.url
                                                           label:self.story.title
                                                           value:nil] build]];

    NSString *shareText = [NSString stringWithFormat:@"\"%@\" via @Scanvine", [self.story title]];
    NSArray *items = [NSArray arrayWithObjects:shareText, [NSURL URLWithString:self.story.url], nil];
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self.caller presentViewController:avc animated:YES completion:nil];
}

- (void) stopShareLoad:(id)sender {
    if (self.shareLoading) {
        [self.shareLoading stopAnimating];
        [self.shareLoading removeFromSuperview];
        self.shareLoading = nil;
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setNeedsLayout];
}

- (void) deleteStory:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Delete?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [sheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[self.story cachedFilePath] error:nil];
    if (success)
        self.story.cached = [NSNumber numberWithBool:NO];
    [self setNeedsLayout];
}

- (void)loadImageForView:(UIButton*)button forStory:(SVStory *)story
{
    NSString *imageURL = [story imageURL];
    if (!imageURL || imageURL.class==NSNull.class || ![imageURL hasPrefix:@"http"]) {
        [button setImage:nil forState:UIControlStateNormal];
        [button setNeedsDisplay];
        self.story.image = nil;
        return;
    }

    if (self.story.image) {
        [button setImage:self.story.image forState:UIControlStateNormal];
        [button setNeedsDisplay];
        return;
    }
    
    NSString *file = [story cachedImageFilePath];
    NSData *cachedData = [[NSFileManager defaultManager] fileExistsAtPath:file] ? [NSData dataWithContentsOfFile:file] : nil;
    
    if (cachedData) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self.story) {
                self.story.image = [UIImage imageWithData:cachedData];
                if (button) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (button && self.story && self.story.image) {
                            @try {
                                [button setImage:self.story.image forState:UIControlStateNormal];
                                [button setNeedsDisplay];
                            }
                            @catch (NSException *ex) {
                                NSLog(@"Caught exception %@", ex);
                                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Caught Exception - Cached Image"
                                                                                      action:[ex name]
                                                                                       label:[ex reason]
                                                                                       value:nil] build]];
                            }
                        }
                    });
                }
            }
        });
    }
    else {
        [button setImage:nil forState:UIControlStateNormal];
        NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse * response, NSData * remoteData, NSError * connectionError)
         {
             if (remoteData && self.story) {
                 UIImage *image = [UIImage imageWithData:remoteData];
                 CGSize newSize = CGSizeMake(100.0,100.0);
                 UIGraphicsBeginImageContext(newSize);
                 [image drawInRect:CGRectMake(0, 0, newSize.width,newSize.height)];
                 UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
                 UIGraphicsEndImageContext();
                 self.story.image = newImage;
                 NSData *newData = UIImagePNGRepresentation(self.story.image);
                 [newData writeToFile:[story cachedImageFilePath] atomically:YES];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (button && self.story && self.story.image) {
                         @try {
                             [button setImage:self.story.image forState:UIControlStateNormal];
                             [button setNeedsDisplay];
                         }
                         @catch (NSException *ex) {
                             NSLog(@"Caught exception %@", ex);
                             id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                             [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Caught Exception - Downloaded Image"
                                                                                   action:[ex name]
                                                                                    label:[ex reason]
                                                                                    value:nil] build]];
                         }
                     }
                 });
             }
         }];
    }
}

- (void)dealloc {
    [self.story removeObserver:self forKeyPath:@"cached"];
}

@end
