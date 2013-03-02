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

#import "ADKClip.h"

@interface ADKMasterViewController () {
    NSMutableArray *_objects;
}
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
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self.navigationController setToolbarHidden:NO];
    
    NSString *tmpStatusString = @"2.4 seconds"; // \nThere's no sign of intelligent life down here.";
       
    UILabel *tmpStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    [tmpStatusLabel setBackgroundColor:[UIColor clearColor]];
    [tmpStatusLabel setTextColor:[UIColor colorWithWhite:1.0f alpha:1.0f]];
    [tmpStatusLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.5f]];
    [tmpStatusLabel setShadowOffset:CGSizeMake(0, -1)];
    [tmpStatusLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    [tmpStatusLabel setNumberOfLines:1];
    [tmpStatusLabel setText:tmpStatusString];
    [tmpStatusLabel sizeToFit];
    
    UIProgressView *tmpProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [tmpProgressView setProgress:0.3f];
    
    
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
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[ADKClip clip] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Buttons
- (void)share
{
    // do something
    [ADKShareSheetViewController shareItem:@"whargarbatarl" fromVC:self];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }


    ADKClip *clip = _objects[indexPath.row];
    cell.textLabel.text = clip.title;
    // cell.detailTextLabel.text = clip.description;
    cell.detailTextLabel.text = clip.date.description;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    return YES; // for now. 
}

@end
