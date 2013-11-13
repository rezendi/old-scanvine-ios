//
//  SVHTTPClient.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVHTTPClient.h"

@implementation SVHTTPClient

+ (id)sharedHTTPClient
{
    static dispatch_once_t pred = 0;
    __strong static id __httpClient = nil;
    dispatch_once(&pred, ^{
        __httpClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.scanvine.com/"]];
    });
    return __httpClient;
}

@end
