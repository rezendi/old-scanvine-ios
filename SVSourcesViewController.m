//
//  SVSourcesViewController.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-22.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVSourcesViewController.h"
#import "SVSourceTableViewCell.h"
#import "SVMasterViewController.h"
#import "SVHTTPClient.h"
#import "SVUtil.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface SVSourcesViewController ()

@end

@implementation SVSourcesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    [self.tableView registerClass:SVSourceTableViewCell.class forCellReuseIdentifier:@"Source"];

    self.title = @"Sources";

    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [directory stringByAppendingPathComponent:@"latest_sources"];
    self.json = [NSDictionary dictionaryWithContentsOfFile:file];
    [self reload];
    [self fetch];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Sources"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)reload {
    if (!self.json)
        return;
    self.sources = self.json[@"sources"];
    [self.tableView reloadData];
}

- (void)fetch {
    [self showLoading];
    [[SVHTTPClient sharedHTTPClient] getPath:[SVUtil apiPathFor:@"sources"] parameters:nil
     success:^(AFHTTPRequestOperation *operation, id responseObject){
         NSLog(@"API source fetch success");
         [self stopLoading];
         NSError* JSONError = nil;
         self.json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&JSONError];
         if(JSONError || !self.json){
             NSLog(@"Error: %@", JSONError);
             [SVUtil showAlertWithTitle:@"Server error" andMessage:@"Unable to parse server source list. Sorry! Please try again later."];
             return;
         }
         NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
         NSString *file = [directory stringByAppendingPathComponent:@"latest_sources"];
         BOOL success = [self.json writeToFile:file atomically:YES];
         if (success) {
             NSURL *fileURL = [NSURL fileURLWithPath:file];
             [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey: NSURLIsExcludedFromBackupKey error: nil];
             [self reload];
         }
         else {
             NSLog(@"Unable to write latest sources to file");
             [SVUtil showAlertWithTitle:@"Cache error" andMessage:@"Unable to cache server source list for offline use."];
         }
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"API fetch failed: %@",[error localizedDescription]);
         [SVUtil showAlertWithTitle:@"Fetch error" andMessage:@"Unable to fetch source data from server. Using cached list, if any. Sorry! Please try again later."];
         [self stopLoading];
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sources ? self.sources.count+1 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Source";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.row==0) {
        cell.textLabel.text = @"Source";
        cell.detailTextLabel.text = @"Average Score";
    }
    else {
        NSUInteger row = indexPath.row-1;
        cell.textLabel.text = [self.sources objectAtIndex:row][@"name"];
        cell.detailTextLabel.text = [[self.sources objectAtIndex:row][@"average_score"] stringValue];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0) {
        sortByName = !sortByName;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:(sortByName ? @"name" : @"average_score")
                                                               ascending:(sortByName ? YES : NO)];
        self.sources = [self.sources sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
        [self.tableView reloadData];
    }
    else {
        SVMasterViewController *mvc = [[SVMasterViewController alloc] initWithNibName:nil bundle:nil];
        mvc.source = [self.sources objectAtIndex:indexPath.row-1];
        [self.navigationController pushViewController:mvc animated:YES];
    }
}

@end
