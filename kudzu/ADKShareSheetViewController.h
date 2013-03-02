//
//  ADKShareSheetViewController.h
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface ADKShareSheetViewController : UIViewController<MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

+(void)shareItem:(id)itemToShare fromVC:(UIViewController *)presentingViewController;

@end
