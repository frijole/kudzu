//
//  ADKEditableTableViewCell.h
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ADKClip.h"

@interface ADKEditableTableViewCell : UITableViewCell

@property (nonatomic, retain) ADKClip *clip;

@property (nonatomic, assign) UITextField *textField;
@property (nonatomic, assign) UITextField *detailTextField;

@end
