//
//  ADKClip.h
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADKClip : NSObject <NSCoding>

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;

@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSURL *movieURL;
@property (nonatomic) CGFloat duration;

+ (ADKClip *)clip;

@end