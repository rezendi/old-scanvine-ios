//
//  SVDisplayViewController.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVDisplayViewController.h"
#import "SVMasterViewController.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface SVDisplayViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation SVDisplayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configureView];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.webView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Business logic

- (void)setStory:(SVStory *)newStory
{
    if (_story != newStory) {
        _story = newStory;
        self.title = self.story.title;
    }
    
    if (self.masterPopoverController != nil)
        [self.masterPopoverController dismissPopoverAnimated:YES];
}

- (void)configureView
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    self.webView.frame = self.view.bounds;
    [self showLoading];
    if (self.story) {
        self.webView.scalesPageToFit = YES;
        if ([self.story isCached]) {
            NSDictionary *json = [NSDictionary dictionaryWithContentsOfFile:self.story.cachedFilePath];
            [self.webView loadHTMLString:json[@"html"] baseURL:nil];
            [tracker set:kGAIScreenName value:@"Cached Story"];
        }
        else {
            NSURL *url = [[NSURL alloc] initWithString:[self.story url]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            [self.webView loadRequest:request];
            [tracker set:kGAIScreenName value:@"Story"];
        }
    }
    else {
        self.title = @"About Scanvine";
        self.webView.scalesPageToFit = NO;
        NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
        NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
        [self.webView loadHTMLString:htmlString baseURL:nil];
        [tracker set:kGAIScreenName value:@"About"];
    }
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.story)
        [self showOptions];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Web view error: %@", [error userInfo]);
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

#pragma mark - UI

-(void)showLoading {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = barButton;
    [activityIndicator startAnimating];
}

-(void)showOptions {
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"options"] style:UIBarButtonItemStyleBordered target:self action:@selector(options:)];
    self.navigationItem.rightBarButtonItem = optionsButton;
}

- (void)options:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"More"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"From Source", @"From Author", nil];
    sheet.tag = 1;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    NSString *selected = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([@"From Author" isEqualToString:selected]) {
        SVMasterViewController *mvc = [[SVMasterViewController alloc] initWithNibName:nil bundle:nil];
        mvc.author = self.story.vals[@"author"];
        [self.navigationController pushViewController:mvc animated:YES];
    }
    if ([@"From Source" isEqualToString:selected]) {
        SVMasterViewController *mvc = [[SVMasterViewController alloc] initWithNibName:nil bundle:nil];
        mvc.source = self.story.vals[@"source"];
        [self.navigationController pushViewController:mvc animated:YES];
    }
}


#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
