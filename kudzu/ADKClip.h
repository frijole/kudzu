//
//  ADKClip.h
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADKClip : NSObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;

+ (ADKClip *)clip;

@end