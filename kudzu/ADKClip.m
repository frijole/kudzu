//
//  ADKClip.m
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKClip.h"

#define ADKClipDateKey          @"ADKClipDateKey"
#define ADKClipTitleKey         @"ADKClipTitleKey"
#define ADKClipDescriptionKey   @"ADKClipDescriptionKey"
#define ADKClipThumbnailKey     @"ADKClipThumbnailKey"
#define ADKClipMovieKey         @"ADKClipMovieKey"
#define ADKClipDurationKey      @"ADKClipDurationKey"

@implementation ADKClip

+ (ADKClip *)clip
{
    ADKClip *rtnClip = [[ADKClip alloc] init];
    
    // rtnClip.title = @"new clip";
    // rtnClip.description = @"no desciption";
    rtnClip.date = [NSDate date];
    rtnClip.thumbnail = [UIImage imageNamed:@"placeholder"];

    return rtnClip;
}

/*
 @property (nonatomic, retain) NSDate *date;
 @property (nonatomic, retain) NSString *title;
 @property (nonatomic, retain) NSString *description;
 
 @property (nonatomic, retain) UIImage *thumbnail;
 @property (nonatomic, retain) NSURL *movieURL;
 */
#pragma mark - NSCoding Protocol
- (void)encodeWithCoder:(NSCoder *)coder
{
    self.date ? [coder encodeObject:self.date forKey:ADKClipDateKey] : nil;
    self.title ? [coder encodeObject:self.title forKey:ADKClipTitleKey] : nil;
    self.description ? [coder encodeObject:self.description forKey:ADKClipDescriptionKey] : nil;
    
    self.thumbnail ? [coder encodeObject:self.thumbnail forKey:ADKClipThumbnailKey] : nil;
    self.movieURL ? [coder encodeObject:self.movieURL forKey:ADKClipMovieKey] : nil;
    self.duration ? [coder encodeFloat:self.duration forKey:ADKClipDurationKey] : nil;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.date = [coder decodeObjectForKey:ADKClipDateKey];
        self.title = [coder decodeObjectForKey:ADKClipTitleKey];
        self.description = [coder decodeObjectForKey:ADKClipDescriptionKey];
        self.thumbnail = [coder decodeObjectForKey:ADKClipThumbnailKey];
        self.movieURL = [coder decodeObjectForKey:ADKClipMovieKey];
        self.duration = [coder decodeFloatForKey:ADKClipDurationKey];
    }
    return self;
}

@end
