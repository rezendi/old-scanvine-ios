//
//  SVUtil.h
//  Scanvine
//
//  Created by Jon Evans on 2013-09-21.
//  Copyright (c) 2013 scanvine.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVUtil : NSObject

+(NSString*) apiPathFor:(NSString*)path;
+(void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message;

@end
