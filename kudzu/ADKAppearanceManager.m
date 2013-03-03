//
//  ADKAppearanceManager.m
//  kudzu
//
//  Created by Ian Meyer on 3/3/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKAppearanceManager.h"

@implementation ADKAppearanceManager

+ (void)setup
{
    // navigation bar
    [[UINavigationBar appearance] setTintColor:[UIColor lightGrayColor]];
    
    // toolbar
    [[UIToolbar appearance] setTintColor:[UIColor lightGrayColor]];

    // progress bar
    [[UIProgressView appearance] setTrackTintColor:[UIColor darkGrayColor]];

}

@end
