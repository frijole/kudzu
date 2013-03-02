//
//  ADKClip.m
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKClip.h"

@implementation ADKClip

+ (ADKClip *)clip
{
    ADKClip *rtnClip = [[ADKClip alloc] init];
    
    rtnClip.title = @"untitled";
    rtnClip.date = [NSDate date];
    
    return rtnClip;
}

@end
