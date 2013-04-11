//
//  ADKMasterViewController.m
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKMasterViewController.h"

#import "ADKDetailViewController.h"
#import "ADKShareSheetViewController.h"
#import "ADKEditableTableViewCell.h"

#import "ADKClip.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "AVAssetStitcher.h"

#import "MBProgressHUD.h"

#define kADKDataStoreArchiveKey @"archive"
#define kADKShowDetailButton    NO
#define kADKCameraAvailable     [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]

#define kADKAlertViewTagTrash   42

#define kADKOutputSize          CGSizeMake(1280.0f,720.0f)

static ALAssetsLibrary *assetLibrary = nil;

@interface ADKMasterViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIVideoEditorControllerDelegate, UIAlertViewDelegate>
{
    NSMutableArray *_objects;
    
    UIImageView *_tips;
}

@property (nonatomic, retain) UIImagePickerController *moviePicker;

@property (nonatomic, assign) UILabel *statusLabel;
@property (nonatomic, assign) UIProgressView *progressView;

@end

@implementation ADKMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"kudzu", @"kudzu");
    }
    
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    [self setClearsSelectionOnViewWillAppear:YES];
    
    if ( [self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)] )
        [self.tableView registerClass:[ADKEditableTableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.tableView setRowHeight:60.0f];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self.navigationController setToolbarHidden:NO];

    NSString *tmpStatusString = @"Total\n-- sec";
    UILabel *tmpStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    [tmpStatusLabel setBackgroundColor:[UIColor clearColor]];
    [tmpStatusLabel setTextColor:[UIColor colorWithWhite:1.0f alpha:1.0f]];
    [tmpStatusLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.5f]];
    [tmpStatusLabel setShadowOffset:CGSizeMake(0, -1)];
    [tmpStatusLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    [tmpStatusLabel setNumberOfLines:2];
    [tmpStatusLabel setText:tmpStatusString];
    _statusLabel = tmpStatusLabel;
    
    UIProgressView *tmpProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
//    CGRect tmpProgressFrame = tmpProgressView.frame;
//    tmpProgressFrame.size.width = 100;
//    [tmpProgressView setFrame:tmpProgressFrame];
    [tmpProgressView setProgress:0.0f];
    _progressView = tmpProgressView;
    
    UIBarButtonItem *tmpStatus = [[UIBarButtonItem alloc] initWithCustomView:tmpStatusLabel];
    UIBarButtonItem *tmpProgress = [[UIBarButtonItem alloc] initWithCustomView:tmpProgressView];
    UIBarButtonItem *tmpFlexible1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *tmpFlexible2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    // UIBarButtonItem *tmpFixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *tmpShareBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    
    [self setToolbarItems:@[tmpStatus, tmpFlexible1, tmpProgress, tmpFlexible2, tmpShareBBI]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshData];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons
- (void)trashButtonPressed
{
    UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"kudzu"
                                                           message:@"remove all clips?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"Remove", nil];
    [tmpAlertView setTag:42];
    [tmpAlertView show];
}

- (void)addButtonPressed
{
    if ( kADKCameraAvailable ) {
        // action sheet for camera, photo library
        UIActionSheet *tmpActionSheet = [[UIActionSheet alloc] initWithTitle:@"Add A Clip"
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:@"Record A Video", @"Select From Library", nil];
        [tmpActionSheet showFromToolbar:self.navigationController.toolbar];
    } else {
        // photo library only
        [self moviePickerFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)share
{
    if ( self.objects.count == 0 ) {
        NSLog(@"can't share nothing!");

        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"kudzu"
                                                               message:@"Nothing to Export\n\nAdd some clips!"
                                                              delegate:nil
                                                     cancelButtonTitle:nil
                                                     otherButtonTitles:@"OK", nil];
        [tmpAlertView show];

        return;
    } else if ( self.objects.count == 1 ) {
        NSLog(@"can't share one thing!");
        
        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"kudzu"
                                                               message:@"Nothing to Export\n\nAdd some more clips!"
                                                              delegate:nil
                                                     cancelButtonTitle:nil
                                                     otherButtonTitles:@"OK", nil];
        [tmpAlertView show];
        
        return;
    }
    
    // do something
    // [ADKShareSheetViewController shareItem:@"whargarbatarl" fromVC:self];

    [[self.toolbarItems lastObject] setEnabled:NO];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.animationType = MBProgressHUDAnimationFade;
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Exporting...";
    hud.detailsLabelText = @"The video will be saved in the\n'kudzu output' album in the photo library.";
    
    NSMutableArray *tmpClipURLs = [NSMutableArray array];
    
    for ( ADKClip *clip in self.objects ) {
        if ( clip.movieURL )
            [tmpClipURLs addObject:clip.movieURL];
    }

    [self mergeVideos:tmpClipURLs];
}

- (void)refreshData
{
    // if we don't have any data, hide the table and show the tips.
    if ( self.objects.count == 0 ) {
        // [self.tableView setHidden:YES];
        // [self.tableView setBackgroundColor:[UIColor colorWithRed:45/255.0f green:75/255.0f blue:60/255.0f alpha:1.0f]];
        // [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.8f alpha:1.0f]];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        // more
        UIImage *tmpImage = [UIImage imageNamed:@"tips"];
        if ( !_tips && tmpImage ) {
            _tips = [[UIImageView alloc] initWithImage:tmpImage];
            CGRect tmpFrame = self.tableView.bounds;
            tmpFrame.size.width -= 10;
            tmpFrame.origin.y += 10;
            tmpFrame.size.height -= 10;
            [_tips setFrame:tmpFrame];
            [_tips setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
            [_tips setContentMode:UIViewContentModeTopRight];
            [_tips setBackgroundColor:[UIColor clearColor]];
            [self.view addSubview:_tips];
        }
    } else {
        // we have data, make sure the table is visible
        // [self.tableView setHidden:NO];
        // [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        
        if ( _tips ) {
            [_tips removeFromSuperview];
            _tips = nil;
        }
        
    } // and continue...
    
    
    // whenever we're going to appear, recalculate the total time
    CGFloat tmpTotalTime = 0.0f;
    for ( ADKClip *clip in self.objects )
    {
        tmpTotalTime += clip.duration;
    }
    
    // reusable number formatter
    static NSNumberFormatter *numberFormatter = nil;
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setMaximumFractionDigits:2]; // up to two digits on the right
        [numberFormatter setMinimumIntegerDigits:1]; // at least one digit on the left
    }
    NSString *tmpStatusString = [NSString stringWithFormat:@"Total\n%@ sec",[numberFormatter stringFromNumber:[NSNumber numberWithFloat:tmpTotalTime]]];
    [self.statusLabel setText:tmpStatusString];
    
    if ( tmpTotalTime > 6.0f ) {
        [_progressView setProgressTintColor:[UIColor redColor]];
    } else {
        [_progressView setProgressTintColor:nil];
    }
    
    [_progressView setProgress:(tmpTotalTime/6.0f) animated:NO];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // kick off whatever's next, depending on the button index
    switch ( buttonIndex ) {
        case 0:
            [self moviePickerFromSource:UIImagePickerControllerSourceTypeCamera];
            break;
        case 1:
            [self moviePickerFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        default:
            break;
    }
}

#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch ( alertView.tag ) {

        case kADKAlertViewTagTrash:
            // trash one!
            if ( buttonIndex != alertView.cancelButtonIndex ) {
                // confirmed clearing all clips
                [self setEditing:NO animated:YES];

                [self.objects removeAllObjects];
                [self saveToDisk];
                // [self.tableView reloadData];
                [self.tableView deleteRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self refreshData];
            }
            
            break;
            
        default:
            NSLog(@"unknown alert view");
            break;
    }
    
}


#pragma mark - Movie Picker / UIImagePickerControllerDelegate
- (void)moviePickerFromSource:(UIImagePickerControllerSourceType)inSourceType
{
    // present image picker to get a video
    if ( !self.moviePicker ) {
        self.moviePicker = [[UIImagePickerController alloc] init];
        self.moviePicker.allowsEditing = YES;
        self.moviePicker.videoMaximumDuration = 5.0f;
        self.moviePicker.delegate = self;
        self.moviePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
    }
    
    // check for camera
    BOOL canUseCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    
    if ( inSourceType == UIImagePickerControllerSourceTypeCamera && !canUseCamera ) {
        NSLog(@"trying to load a camera but a camera is not available");
        return;
    }
    // we're good to proceed...
    
    // (re)set the source type, and present
    self.moviePicker.sourceType = inSourceType;
    [self presentModalViewController:self.moviePicker animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL *tmpMovieURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    // if we came from the camera, we need to save the video.
    if ( [picker sourceType] == UIImagePickerControllerSourceTypeCamera ) {
        
        if ( tmpMovieURL ) {
            [self saveMovie:tmpMovieURL toAlbum:@"kudzu recordings" withCompletionBlock:^(NSError *error) {
                if (error!=nil) {
                    NSLog(@"Failed to save recording with error: %@", [error description]);
                }
            }];
        }
    }
    
//    // we want to present an editing interface for the movie at this url.
//    if ( [UIVideoEditorController canEditVideoAtPath:[tmpMovieURL absoluteString]] ) {
//        dispatch_async( dispatch_get_main_queue(), ^{
//            UIVideoEditorController *videoEditorController = [[UIVideoEditorController alloc] init];
//            videoEditorController.delegate = self;
//            videoEditorController.videoMaximumDuration = 0.0;
//            videoEditorController.videoQuality = UIImagePickerControllerQualityTypeHigh;
//            videoEditorController.videoPath = [tmpMovieURL absoluteString];
//            [picker.presentingViewController presentModalViewController:videoEditorController animated:YES];
//        });
//    } else {
//        NSLog(@"cannot edit video at path: %@", [tmpMovieURL absoluteString]);

    // adding it as-is
    // create a new ADKClip...
    ADKClip *tmpClip = [ADKClip clip];
    tmpClip.movieURL = tmpMovieURL;
    
    // get the duration by making an AVPlayerItem
    // generate a thumbnail, too. (this is ugly, but apparently works? via http://stackoverflow.com/a/6027285)
    AVPlayerItem *tmpPlayerItem = [AVPlayerItem playerItemWithURL:tmpMovieURL];
    MPMoviePlayerController *tmpMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:tmpMovieURL];
    [tmpMoviePlayer setShouldAutoplay:NO];
    [tmpMoviePlayer stop]; // just in case
    
    tmpClip.thumbnail = [tmpMoviePlayer thumbnailImageAtTime:0.0f timeOption:MPMovieTimeOptionNearestKeyFrame];
    tmpClip.duration = CMTimeGetSeconds([tmpPlayerItem duration]);
    
    // we're done with the movie player
    tmpMoviePlayer = nil;
    
    // ditch the avplayer, though
    tmpPlayerItem = nil;
    
    // ...add it to the array...
    [self.objects addObject:tmpClip];
    
    // save it, too
    [self saveToDisk];
    
    // ...and add it to the table
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_objects.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [picker.presentingViewController dismissModalViewControllerAnimated:YES];
    
}

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath
{
    // create a new ADKClip...
    ADKClip *tmpClip = [ADKClip clip];
    tmpClip.movieURL = [NSURL URLWithString:editedVideoPath];
    
    // get the duration by making an AVPlayerItem
    // generate a thumbnail, too. (this is ugly, but apparently works? via http://stackoverflow.com/a/6027285)
    // AVPlayerItem *tmpPlayerItem = [AVPlayerItem playerItemWithURL:tmpMovieURL];
    MPMoviePlayerController *tmpMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:tmpClip.movieURL];
    [tmpMoviePlayer stop]; // just in case
    
    tmpClip.thumbnail = [tmpMoviePlayer thumbnailImageAtTime:0.0f timeOption:MPMovieTimeOptionNearestKeyFrame];
    tmpClip.duration = [tmpMoviePlayer duration];
    
    // we're done with the movie player
    tmpMoviePlayer = nil;
    
    // ditch the avplayer, though
    // tmpPlayerItem = nil;
    
    // Player autoplays audio on init
    [tmpMoviePlayer stop];
    
    // ...add it to the array...
    [self.objects addObject:tmpClip];
    
    // save it, too
    [self saveToDisk];
    
    // ...and add it to the table
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_objects.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Photo Library
- (void)saveMovie:(NSURL *)movieFileURL toAlbum:(NSString*)albumName withCompletionBlock:(void (^)(NSError* error))completionBlock
{
    //write the image data to the assets library (camera roll)
    if ( !assetLibrary ) {
        assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    [assetLibrary writeVideoAtPathToSavedPhotosAlbum:movieFileURL
                                     completionBlock:^(NSURL* assetURL, NSError* error) {
                                   
                                   //error handling
                                   if (error!=nil) {
                                       completionBlock(error);
                                       return;
                                   }
                                   
                                   //add the asset to the custom photo album
                                   [self addAssetURL:assetURL
                                             toAlbum:albumName
                                 withCompletionBlock:completionBlock];
                                   
                               }];
}

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(void (^)(NSError* error))completionBlock
{
    
    //write the image data to the assets library (camera roll)
    if ( !assetLibrary ) {
        assetLibrary = [[ALAssetsLibrary alloc] init];
    }
        
    [assetLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation
                               completionBlock:^(NSURL* assetURL, NSError* error) {
                                   
                                   //error handling
                                   if (error!=nil) {
                                       completionBlock(error);
                                       return;
                                   }
                                   
                                   //add the asset to the custom photo album
                                   [self addAssetURL:assetURL
                                             toAlbum:albumName
                                 withCompletionBlock:completionBlock];
                                   
                               }];
}

-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(void (^)(NSError* error))completionBlock
{
    __block BOOL albumWasFound = NO;
    
    //search all photo albums in the library
	if ( !assetLibrary ) {
		assetLibrary = [[ALAssetsLibrary alloc] init];
	}
    
	[assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    
                                    //compare the names of the albums
                                    if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                                        
                                        //target album is found
                                        albumWasFound = YES;
                                        
                                        //get a hold of the photo's asset instance
                                        [assetLibrary assetForURL: assetURL
                                                      resultBlock:^(ALAsset *asset) {
                                                          
                                                          //add photo to the target album
                                                          [group addAsset: asset];
                                                          
                                                          //run the completion block
                                                          completionBlock(nil);
                                                          
                                                      } failureBlock: completionBlock];
                                        
                                        //album was found, bail out of the method
                                        return;
                                    }
                                    
                                    if (group==nil && albumWasFound==NO) {
                                        //photo albums are over, target album does not exist, thus create it
                                        
                                        //create new assets album
                                        [assetLibrary addAssetsGroupAlbumWithName:albumName
                                                                      resultBlock:^(ALAssetsGroup *group) {
                                                                          
                                                                          //get the photo's instance
                                                                          [assetLibrary assetForURL: assetURL
                                                                                        resultBlock:^(ALAsset *asset) {
                                                                                            
                                                                                            //add photo to the newly created album
                                                                                            [group addAsset: asset];
                                                                                            
                                                                                            //call the completion block
                                                                                            completionBlock(nil);
                                                                                            
                                                                                        } failureBlock: completionBlock];
                                                                          
                                                                      } failureBlock: completionBlock];
                                        
                                        //should be the last iteration anyway, but just in case
                                        return;
                                    }
                                    
                                } failureBlock: completionBlock];
    
}


#pragma mark - Video Merging
- (void)mergeVideos:(NSMutableArray *)videoPathArray
{
    CGSize videoSize = kADKOutputSize;
    
    AVAssetStitcher *stitcher = [[AVAssetStitcher alloc] initWithOutputSize:videoSize];
    
    __block NSError *stitcherError;
    NSMutableArray *temporaryFileURLs;
    
    [temporaryFileURLs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *outputFileURL, NSUInteger idx, BOOL *stop) {
        
        [stitcher addAsset:[AVURLAsset assetWithURL:outputFileURL] withTransform:^CGAffineTransform(AVAssetTrack *videoTrack) {
            
            //
            // The following transform is applied to each video track. It changes the size of the
            // video so it fits within the output size and stays at the correct aspect ratio.
            //
            
            CGFloat ratioW = videoSize.width / videoTrack.naturalSize.width;
            CGFloat ratioH = videoSize.height / videoTrack.naturalSize.height;
            if(ratioW < ratioH)
            {
                CGFloat diffH = videoTrack.naturalSize.height - (videoTrack.naturalSize.height * ratioH);
                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(0, -diffH/2.0), CGAffineTransformMakeScale(ratioH, ratioH) );
            }
            else
            {
                CGFloat diffW = videoTrack.naturalSize.width - (videoTrack.naturalSize.width * ratioW);
                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(-diffW/2.0, 0), CGAffineTransformMakeScale(ratioW, ratioW) );
            }
            
        } withErrorHandler:^(NSError *error) {
            
            stitcherError = error;
            
        }];
        
    }];
    
    if(stitcherError)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:stitcherError.domain
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        // save it to the library?
        
//        [self saveOutputToAssetLibrary:nil completionBlock:^(NSError *saveError) {
//            
//            [UIView animateWithDuration:0.25 animations:^{
//                self.busyView.frame = CGRectMake(self.busyView.frame.origin.x, -self.busyView.frame.size.height, self.busyView.frame.size.width, self.busyView.frame.size.height);
//            } completion:^(BOOL finished) {
//                self.busyView.hidden = YES;
//            }];
//            
//            [[NSFileManager defaultManager] removeItemAtURL:finalOutputFileURL error:nil];
//            
//            self.videoRecrodingProgress.progress = 0.0;
//            self.recordButton.enabled = YES;
//
//        }];
    }
   
    NSURL *finalVideoLocationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@-%ld.mp4", NSTemporaryDirectory(), @"final", (long)[[NSDate date] timeIntervalSince1970]]];

    
    [stitcher exportTo:finalVideoLocationURL
            withPreset:AVAssetExportPreset1280x720
 withCompletionHandler:^(NSError *error) {
     
     [self mergeVideoFinished:finalVideoLocationURL status:0 error:error];
     
 }];
}

- (UIInterfaceOrientation)orientationForVideoTrack:(AVAssetTrack *)videoTrack
{
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
}

- (void)mergeVideoFinished:(NSURL *)combinedURL status:(int)status error:(NSError *)error
{
    // reset share button
    [[self.toolbarItems lastObject] setEnabled:YES];

    if (error == nil) {
        NSLog(@"Merging videos succeeded!");
        
        [self saveMovie:combinedURL toAlbum:@"kudzu output" withCompletionBlock:^(NSError *error) {
            // NSLog(@"saved merged video");
            dispatch_async( dispatch_get_main_queue(), ^{

                MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
                if ( hud ) {
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                    hud.labelText = @"Done!";
                    hud.detailsLabelText = @"The video bas been saved in the\n'kudzu output' album in the photo library.";
                    
                    double delayInSeconds = 2.0f;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                        // enable the button, too
                        [[self.navigationController.toolbar.items lastObject] setEnabled:YES];
                    });
                }
//                UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"kudzu"
//                                                                       message:@"Saved to Photo Library"
//                                                                      delegate:nil
//                                                             cancelButtonTitle:nil
//                                                             otherButtonTitles:@"OK", nil];
//                [tmpAlertView show];
            });

        }];
        
        // share sheet!
        // AVAsset *finishedAsset = [AVAsset assetWithURL:combinedURL];
        // [ADKShareSheetViewController shareItem:finishedAsset fromVC:self];
        // nothing will appear for this AVAsset :(

    } else {
        NSLog(@"Merging videos failed D: #%@",error);
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
            if ( hud ) {
                hud.mode = MBProgressHUDModeCustomView;
                hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"xmark"]];
                hud.labelText = @"Export Failed";
                hud.detailsLabelText = @"Sorry about that D:";
                
                double delayInSeconds = 2.0f;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                });
            }
            //                UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"kudzu"
            //                                                                       message:@"Export Failed :("
            //                                                                      delegate:nil
            //                                                             cancelButtonTitle:nil
            //                                                             otherButtonTitles:@"OK", nil];
            //                [tmpAlertView show];
        });
    }
}


- (UIInterfaceOrientation)orientationForAsset:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIInterfaceOrientation rtnOrientation = [self orientationForVideoTrack:videoTrack];
    return rtnOrientation;
}

#pragma mark - Data Storage
- (NSMutableArray *)objects
{
    // ...make sure we have a place to put it...
    if (!_objects) {
        // try to load from disk
        if ( [self loadFromDisk] ) {
            NSLog(@"loaded from disk");
        } else {
            NSLog(@"load from disk failed.");
             _objects = [[NSMutableArray alloc] init];
        }
    }
    
    return _objects;
}

- (BOOL)loadFromDisk
{
    BOOL rtnStatus = NO;
    
    // try to read data objects from disk via NSCoding
    NSMutableArray *tmpUnarchivedDataArray = nil; // a place to put it
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    cachePath = [cachePath stringByAppendingString:@"/archivedData"];
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:cachePath];
    if ( codedData ) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
        tmpUnarchivedDataArray = [unarchiver decodeObjectForKey:kADKDataStoreArchiveKey];
        [unarchiver finishDecoding];
    }
    
    if ( tmpUnarchivedDataArray && [tmpUnarchivedDataArray isKindOfClass:[NSArray class]] )
    {   // success!
        _objects = [NSMutableArray arrayWithArray:tmpUnarchivedDataArray];
        rtnStatus = YES;
        NSLog(@"Load Data: Success");
    } else {
        NSLog(@"Load Data: Failed");
    }
    
    return rtnStatus;
}

- (BOOL)saveToDisk
{
    BOOL rtnStatus = NO;
    
    // use NSCoding to write out our data objects
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    // make sure we have something to save and somewhere to save it
    // if ( _objects.count > 0 ) {
        cachePath = [cachePath stringByAppendingString:@"/archivedData"];
        // rtnStatus = [tmpArchivingArray writeToFile:cachePath atomically:YES];
        
        NSMutableData *tmpDataToSave = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:tmpDataToSave];
        [archiver encodeObject:self.objects forKey:kADKDataStoreArchiveKey];
        [archiver finishEncoding];
        rtnStatus = [tmpDataToSave writeToFile:cachePath atomically:YES];
    // }
    
    if ( rtnStatus )
        NSLog(@"Save Data: Success");
    else
        NSLog(@"Save Data: Failed");
    
    return rtnStatus;
}


#pragma mark - Table View
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if ( !editing ) {
        // add button
        UIBarButtonItem *tmpAddButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        [self.navigationItem setRightBarButtonItem:tmpAddButton animated:YES];
    } else {
        UIBarButtonItem *tmpClearButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashButtonPressed)];
        [tmpClearButton setTintColor:[UIColor redColor]];
        [self.navigationItem setRightBarButtonItem:tmpClearButton animated:YES];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count;
}

// Customize the appearance of table view cells.
- (ADKEditableTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    
    ADKEditableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ADKEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    ADKClip *clip = _objects[indexPath.row];
    [cell setClip:clip];
    
    cell.accessoryType = kADKShowDetailButton ? UITableViewCellAccessoryDetailDisclosureButton :UITableViewCellAccessoryNone;

    // NSLog(@"cellForRow (%p) title: %@", cell, cell.textLabel.text);

    return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"willDisplayCell (%p) title: %@", cell, cell.textLabel.text);
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        // take it out of the array
        [_objects removeObjectAtIndex:indexPath.row];

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.animationType = MBProgressHUDAnimationFade;
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Deleting...";
        
        // and dispatch saving it
        static dispatch_queue_t myQueue = nil;
        if ( !myQueue )
            myQueue = dispatch_queue_create("myQueue", NULL);
        
        dispatch_async(myQueue, ^{
            // save it in the background
            [self saveToDisk];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // udpate the UI when we're done
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self refreshData];

                // update the hud and dismiss it quickly
                MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
                if ( hud ) {
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"xmark"]];
                    hud.labelText = @"Deleted";
                    
                    double delayInSeconds = 1.0f;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                        [self refreshData]; // labels etc
                    });
                }
            });
        });
    
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id tmpObject = [_objects objectAtIndex:fromIndexPath.row];
    [_objects removeObjectAtIndex:fromIndexPath.row];
    [_objects insertObject:tmpObject atIndex:toIndexPath.row];

    // reload the table and see if things jump around or not
    // [self.tableView reloadData];
}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // edit the title?
//    // [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // selection == editing
    // so save edits
    [self saveToDisk];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController) {
        self.detailViewController = [[ADKDetailViewController alloc] initWithNibName:@"ADKDetailViewController" bundle:nil];
    }
    NSDate *object = _objects[indexPath.row];
    self.detailViewController.detailItem = object;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark - iOS 5 Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return ( UIInterfaceOrientationIsLandscape(toInterfaceOrientation) || UIInterfaceOrientationIsPortrait(toInterfaceOrientation) );
}

@end
