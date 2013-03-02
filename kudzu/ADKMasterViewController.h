//
//  ADKMasterViewController.h
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ADKDetailViewController;

@interface ADKMasterViewController : UITableViewController

@property (strong, nonatomic) ADKDetailViewController *detailViewController;

@end
