//
//  SVMasterViewController.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVMasterViewController.h"
#import "SVStoryTableViewCell.h"
#import "SVDisplayViewController.h"
#import "SVSourcesViewController.h"
#import "SVHTTPClient.h"
#import "SVStory.h"
#import "SVUtil.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "OpenInChromeController.h"

@implementation SVMasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.tableView registerClass:SVStoryTableViewCell.class forCellReuseIdentifier:@"Story"];
    
    self.title = self.source ? self.source[@"name"] : @"Scanvine";
    self.time = self.source ? @"Firehose" : @"Latest";

    //self.navigationController.navigationBar.barTintColor = [UIColor lightGrayColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];

    if (!self.source && !self.author && !self.downloads) {
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleBordered target:self action:@selector(menu:)];
        self.navigationItem.leftBarButtonItem = menuButton;
    }
    [self showOptions];

    if (self.downloads) {
        self.stories = [SVStory allDownloadedStories];
        [self configureTitle];
        [self.tableView reloadData];
    }
    else
        [self fetch];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Dispose of any resources that can be recreated.
}

- (void)preferredContentSizeChanged:(NSNotification *)aNotification {
    [self.tableView reloadData];
}

#pragma mark - Load data

- (void)reload {
    if (!self.json)
        return;
    NSMutableArray *stories = [NSMutableArray arrayWithCapacity:self.json.count];
    for (NSDictionary *storyVals in self.json[@"stories"]) {
        [stories addObject:[SVStory storyFromDict:storyVals]];
    }
    self.stories = [stories copy];
    [self configureTitle];
    [self.tableView reloadData];
}

-(void)fetch {
    NSString *path = self.time;
    if ([@"Last Day" isEqualToString:path])
        path = @"Last1";
    else if ([@"Last Week" isEqualToString:path])
        path = @"Last7";
    else if ([@"Last Month" isEqualToString:path])
        path = @"Last30";

    if (self.source) {
        if ([@"Firehose" isEqualToString:path])
            path = [NSString stringWithFormat:@"source/%@", self.source[@"slug"]];
        else
            path = [NSString stringWithFormat:@"source/%@/%@", self.source[@"slug"], path];
    }
    else if (self.author)
        path = [NSString stringWithFormat:@"author/%@", self.author[@"slug"]];
    else if (self.section)
        path = [path stringByAppendingFormat:@"/%@", self.section];

    [self showLoading];
    [[SVHTTPClient sharedHTTPClient] getPath:[SVUtil apiPathFor:path] parameters:nil
     success:^(AFHTTPRequestOperation *operation, id responseObject){
         NSLog(@"API stories fetch success for path %@", path);
         [self showOptions];
         NSError* JSONError = nil;
         self.json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&JSONError];
         if(JSONError || !self.json){
             NSLog(@"Error getting latest stories: %@", JSONError);
             [SVUtil showAlertWithTitle:@"Server error" andMessage:@"Unable to parse server response. Sorry! Please try again later."];
             return;
         }

         NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
         NSString *file = [directory stringByAppendingPathComponent:@"latest_stories"];
         NSMutableDictionary *storiesDict = [NSMutableDictionary dictionaryWithCapacity:2];
         NSData *valsData = [NSJSONSerialization dataWithJSONObject:self.json options:0 error:nil];
         storiesDict[@"latest_stories"] = [[NSString alloc] initWithData:valsData encoding:NSUTF8StringEncoding];
         BOOL success = [storiesDict writeToFile:file atomically:YES];
         if (success) {
             NSURL *fileURL = [NSURL fileURLWithPath:file];
             [fileURL setResourceValue:[NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: nil];
             [self reload];
         }
         else {
             NSLog(@"Unable to write latest stories to file");
             [SVUtil showAlertWithTitle:@"Cache error" andMessage:@"Unable to cache server response for offline use."];
         }
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"API stories fetch failed: %@ %@", path, [error localizedDescription]);
         [SVUtil showAlertWithTitle:@"Fetch error" andMessage:@"Unable to fetch source data from server. Displaying most recent story list, if any. Sorry! Please try again later."];
         [self loadCachedStories];
         [self showOptions];
     }];
}

- (void)loadCachedStories {
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [directory stringByAppendingPathComponent:@"latest_stories"];
    NSDictionary *json = [NSDictionary dictionaryWithContentsOfFile:file];
    if (json) {
        NSData *jsonData = [json[@"latest_stories"] dataUsingEncoding:NSUTF8StringEncoding];
        self.json= [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    }
    [self reload];
}


#pragma mark - Menus

- (void)menu:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Menu"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Sections", @"Downloads", @"Sources", @"About", @"Open stories in", nil];
    sheet.tag = 0;
    [sheet showInView:self.view];
}

- (void)options:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Time"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Firehose", @"Latest", @"Last Day", @"Last Week", @"Last Month", nil];
    sheet.tag = 1;
    [sheet showInView:self.view];
}

- (void)sections:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Section"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"All", @"World", @"Tech", @"Business", @"Entertainment", @"Sports", @"Life",  nil];
    sheet.tag = 2;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==actionSheet.cancelButtonIndex)
        return;

    NSString *selected = [actionSheet buttonTitleAtIndex:buttonIndex];

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Option Selected"
                                                          action:actionSheet.title
                                                           label:selected
                                                           value:nil] build]];

    BOOL doFetch = YES;
    if (actionSheet.tag==0) {
        doFetch = NO;
        if ([@"Sections" isEqualToString:selected])
            [self sections:nil];
        else if ([@"Sources" isEqualToString:selected])
            [self showSources];
        else if ([@"Downloads" isEqualToString:selected])
            [self showDownloads];
        else if ([@"Open stories in" isEqualToString:selected])
            [self launchSettings];
        if ([@"About" isEqualToString:selected])
            [self launchAbout];
    }
    else if (actionSheet.tag==1) {
        self.time = selected;
    }
    else if (actionSheet.tag==2) {
        if ([@"All" isEqualToString:selected])
            self.section = nil;
        else
            self.section = selected;
    }
    else if (actionSheet.tag==3) {
        doFetch = NO;
        [[NSUserDefaults standardUserDefaults] setValue:selected forKey:@"open_links"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    if (doFetch)
        [self fetch];
}

- (void)launchAbout {
    SVDisplayViewController *dvc = [[SVDisplayViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:dvc animated:YES];
}

- (void)showDownloads {
    SVMasterViewController *mvc = [[SVMasterViewController alloc] initWithNibName:nil bundle:nil];
    mvc.downloads = [NSNumber numberWithBool:YES];
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)showSources {
    SVSourcesViewController *svc = [[SVSourcesViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:svc animated:YES];
}

- (void)launchSettings {
    BOOL hasChrome= ([[OpenInChromeController sharedInstance] isChromeInstalled]);
    NSString *first = @"Safari";
    NSString *second = hasChrome ? @"Chrome" : nil;

    NSString *current = [[NSUserDefaults standardUserDefaults] valueForKey:@"open_links"];
    if (!current || [@"Scanvine" isEqualToString:current])
        current = @"Scanvine";
    else if ([@"Safari" isEqualToString:current]) {
        current = @"Safari";
        first = @"Scanvine";
        if (hasChrome)
            second = @"Chrome";
    }
    else if (hasChrome) {
        current = @"Chrome";
        first = @"Scanvine";
        second = @"Safari";
    }
    else {
        current = @"Scanvine";
        first = @"Safari";
    }

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Open links in "
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:current
                                              otherButtonTitles:first, second, nil];
    sheet.tag = 3;
    [sheet showInView:self.view];
}

- (void)configureTitle {
    NSString *title = nil;
    if (self.downloads)
        title = @"Downloads";
    else if (self.author) {
        title = self.author[@"name"];
    }
    else if (self.source) {
        title = [NSString stringWithFormat:@"Scanvine - %@", self.source[@"name"]];
        if (self.time)
            title = [NSString stringWithFormat:@"%@ - %@", self.source[@"name"], self.time];
    }
    else {
        title = [NSString stringWithFormat:@"Scanvine - %@", self.time];
        if (self.section)
            title = [NSString stringWithFormat:@"%@ - %@", self.time, self.section];
    }
    self.title = title;

    //track
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:self.title];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stories ? self.stories.count : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVStory *story = [self.stories objectAtIndex:indexPath.row];
    
    int titleWidth = self.tableView.frame.size.width - 82 - ([story isClustered] ? 20 : 0);
    CGRect titleRect = [[story rankAndTitle] boundingRectWithSize:CGSizeMake(titleWidth, 600)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]}
                                                     context:nil];
    
    float titleHeight = titleRect.size.height > 50 ? titleRect.size.height : 50;
    
    if (story.blurbed) {
        CGRect blurbRect = [[story blurb] boundingRectWithSize:CGSizeMake(titleWidth, 600)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]}
                                                         context:nil];
        titleHeight += blurbRect.size.height+10;
    }

    int bylineWidth = self.tableView.frame.size.width - 120 - ([story isClustered] ? 20 : 0);
    CGRect bylineRect = [[story byline] boundingRectWithSize:CGSizeMake(bylineWidth, 600)
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]}
                                                                context:nil];
    
    return titleHeight + bylineRect.size.height + 45;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVStoryTableViewCell *cell = (SVStoryTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"Story" forIndexPath:indexPath];
    [cell configureForStory:[self.stories objectAtIndex:indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.caller = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVStory *story = [self.stories objectAtIndex:indexPath.row];
    NSURL *url = [NSURL URLWithString:story.url];
    NSString *open = [[NSUserDefaults standardUserDefaults] valueForKey:@"open_links"];
    if (self.downloads)
        [self launchDetailViewFor:story];
    else if ([@"Safari" isEqualToString:open])
        [[UIApplication sharedApplication] openURL:url];
    else if ([@"Chrome" isEqualToString:open] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        [[OpenInChromeController sharedInstance] openInChrome:url
                                              withCallbackURL:[NSURL URLWithString:@"scanvine://"]
                                                 createNewTab:YES];
        }
    else
        [self launchDetailViewFor:story];
}

- (void)reloadCellFor:(id)story {
    NSUInteger n = [self.stories indexOfObject:story];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:n inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)launchDetailViewFor:(SVStory*)story {
    SVDisplayViewController *dvc = [[SVDisplayViewController alloc] initWithNibName:nil bundle:nil];
    dvc.story = story;
    [self.navigationController pushViewController:dvc animated:YES];
}
@end
