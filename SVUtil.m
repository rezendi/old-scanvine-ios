//
//  SVUtil.m
//  Scanvine
//
//  Created by Jon Evans on 2013-09-21.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import "SVUtil.h"
#import "SVHTTPClient.h"

@implementation SVUtil

+(NSString*) apiPathFor:(NSString*)path {
    return [NSString stringWithFormat:@"/api/1/%@", path];
}

+(void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message {
    NSString *key_string = [NSString stringWithFormat:@"showed alert %@", title];
    NSDate *lastShown = [[NSUserDefaults standardUserDefaults] valueForKey:key_string];
    NSTimeInterval howLong = lastShown ? [[NSDate date] timeIntervalSinceDate:lastShown] : 601;
    if (howLong>600) { //don't show same error if <10 min has passed
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:key_string];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
