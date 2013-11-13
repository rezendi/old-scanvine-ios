//
//  SVStory.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-20.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVStory.h"
#import "GTMNSString+HTML.h"

@implementation SVStory

- (id)initWithDict:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        self.vals = dict;
        self.caching = [NSNumber numberWithBool:NO];
    }
    return self;
}

- (NSString*) rankAndTitle {
    NSString *retval = [self.vals[@"title"] gtm_stringByUnescapingFromHTML];
    if (self.vals[@"rank"])
        retval = [NSString stringWithFormat:@"%@. %@", self.vals[@"rank"], retval];
    return retval;
}

-(NSString*) title {
    return [self.vals[@"title"] gtm_stringByUnescapingFromHTML];
}

-(NSString*) blurb {
    return [self.vals[@"blurb"] gtm_stringByUnescapingFromHTML];
}

-(NSString*) byline {
    NSString *bylineText=@"";
    //if (self.vals[@"author"] && [self.vals[@"author"] class]!=NSNull.class)
    //    bylineText = [bylineText stringByAppendingFormat:@"%@, ", self.vals[@"author"][@"name"]];
    
    bylineText = [bylineText stringByAppendingFormat:@"%@", self.vals[@"source"][@"name"]];
    
    NSString *dateString = self.vals[@"timePublished"];
    if (dateString && !([dateString class]==NSNull.class)) {
        if ([dateString rangeOfString:@"."].location != NSNotFound)
            dateString = [dateString substringToIndex:[dateString rangeOfString:@"."].location];
        NSDateFormatter *readFormatter = [self readFormatter];
        NSDate *date = [readFormatter dateFromString:dateString];
        NSDateFormatter *writeFormatter = [self writeFormatter];
        bylineText = [bylineText stringByAppendingFormat:@", %@", [writeFormatter stringFromDate:date]];
    }
    return [bylineText gtm_stringByUnescapingFromHTML];
}

- (NSDateFormatter *)readFormatter {
    static NSDateFormatter *readFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        readFormatter = [[NSDateFormatter alloc] init];
        [readFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    return readFormatter;
}

- (NSDateFormatter *)writeFormatter {
    static NSDateFormatter *writeFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        writeFormatter = [[NSDateFormatter alloc] init];
        [writeFormatter setDateFormat:@"MMM d"];
    });
    return writeFormatter;
}

-(NSString*) imageURL {
    return self.vals[@"image"];
}

-(NSString*) url {
    return self.vals[@"url"];
}

-(NSString*) svid {
    return [self.vals[@"id"] stringValue];
}

-(NSString*) cachedImageFilePath {
    NSString *fileName = [NSString stringWithFormat:@"svimg_%@",self.svid];
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [directory stringByAppendingPathComponent:fileName];
    return file;
}

-(NSString*) cachedFilePath {
    NSString *fileName = [NSString stringWithFormat:@"sv_%@",self.svid];
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [directory stringByAppendingPathComponent:fileName];
    return file;
}

-(void) saveLocally {
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * response, NSData * remoteData, NSError * connectionError)
     {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         self.caching = [NSNumber numberWithBool:NO];
         if (remoteData) {
             NSMutableDictionary *storyDict = [NSMutableDictionary dictionaryWithCapacity:2];
             NSData *valsData = [NSJSONSerialization dataWithJSONObject:self.vals options:0 error:nil];
             storyDict[@"vals"] = [[NSString alloc] initWithData:valsData encoding:NSUTF8StringEncoding];
             storyDict[@"html"] = [[NSString alloc] initWithData:remoteData encoding:NSUTF8StringEncoding];
             BOOL success = [storyDict writeToFile:[self cachedFilePath] atomically:YES];
             if (success) {
                 NSURL *fileURL = [NSURL fileURLWithPath:[self cachedFilePath]];
                 [fileURL setResourceValue:[NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: nil];
                 self.cached = [NSNumber numberWithBool:YES];
             }
             else
                 NSLog(@"Unable to write story to file: %@", self.vals);
         }
     }];
}

-(BOOL) isClustered {
    return [self.vals[@"clustered"] boolValue];
}

-(BOOL) isCached {
    if (!self.cached) {
        NSString *cachePath = [self cachedFilePath];
        BOOL fileCached = [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
        self.cached = [NSNumber numberWithBool:fileCached];
    }
    return [self.cached boolValue];
}

+(SVStory*) storyFromDict:(NSDictionary*)dict {
    return [[SVStory alloc] initWithDict:dict];
}

+(NSArray*) allDownloadedStories {
    NSMutableArray *stories = [NSMutableArray arrayWithCapacity:32];
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'sv_'"];
    NSArray *storyFiles = [dirContents filteredArrayUsingPredicate:filter];
    for (NSString *fileName in storyFiles) {
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        NSDictionary *json = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if (json) {
            NSData *jsonData = [json[@"vals"] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *vals = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            SVStory *story = [SVStory storyFromDict:vals];
            [stories addObject:story];
        }
    }
    return stories;
}

@end
