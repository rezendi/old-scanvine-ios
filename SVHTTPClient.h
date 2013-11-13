//
//  SVHTTPClient.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-19.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface SVHTTPClient : AFHTTPClient

+ (id)sharedHTTPClient;

@end
