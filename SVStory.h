//
//  SVStory.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-20.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVStory : NSObject {}

@property (strong, nonatomic) NSDictionary *vals;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSNumber *caching;
@property (strong, nonatomic) NSNumber *cached;
@property (strong, nonatomic) NSNumber *blurbed;

+(SVStory*) storyFromDict:(NSDictionary*)dict;
+(NSArray*) allDownloadedStories;

-(NSString*) rankAndTitle;
-(NSString*) title;
-(NSString*) byline;
-(NSString*) blurb;
-(NSString*) imageURL;
-(NSString*) svid;
-(NSString*) url;
-(BOOL) isClustered;

-(BOOL) isCached;
-(void) saveLocally;
-(NSString*) cachedFilePath;
-(NSString*) cachedImageFilePath;

@end
