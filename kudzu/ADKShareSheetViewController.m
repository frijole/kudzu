//
//  ADKShareSheetViewController.m
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKShareSheetViewController.h"

@interface ADKShareSheetViewController ()

@end

@implementation ADKShareSheetViewController

+(void)shareItem:(id)itemToShare fromVC:(UIViewController *)presentingViewController
{
	if( NSClassFromString(@"UIActivityViewController") ) {
		// iOS 6: UIActivityViewController
		UIActivityViewController *tmpAVC = [[UIActivityViewController alloc] initWithActivityItems:@[itemToShare] applicationActivities:nil];
		[presentingViewController presentModalViewController:tmpAVC animated:YES];
	}
    else
    {
        // iOS 5: present an action sheet
/*
        // mail
        MFMailComposeViewController *tmpViewController = [[MFMailComposeViewController alloc] init];
        [tmpViewController setMailComposeDelegate:self];
        [tmpViewController setMessageBody:itemToShare isHTML:YES];
        //[tmpViewController addAttachmentData:UIImageJPEGRepresentation(tmpMemory.flattenedImage, 1.0f) mimeType:@"image/jpeg" fileName:[tmpMemory.uid stringByAppendingString:@".jpg"]];
        [presentingViewController presentModalViewController:tmpViewController animated:YES];

        // send message
        MFMessageComposeViewController *tmpViewController = [[MFMessageComposeViewController alloc] init];
        [tmpViewController setBody:@"test email text"];
        [tmpViewController setMessageComposeDelegate:self];
        [presentingViewController presentModalViewController:tmpViewController animated:YES];

*/
	}
}


#pragma mark - MFMailComposeViewController delegate functions
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMessageComposeViewController delegate functions
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	[controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
