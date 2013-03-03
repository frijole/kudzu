//
//  ADKEditableTableViewCell.m
//  kudzu
//
//  Created by Ian Meyer on 3/1/13.
//  Copyright (c) 2013 Adelie Software. All rights reserved.
//

#import "ADKEditableTableViewCell.h"

#define ADKEditableTableViewCellEditTitle       YES
#define ADKEditableTableViewCellEditDetails     NO


@interface ADKEditableTableViewCell ()  <UITextFieldDelegate>
{
    BOOL _editing;
}
@end

@implementation ADKEditableTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setSelectionStyle:UITableViewCellSelectionStyleGray];
    }
    return self;
}

#pragma mark - Editing Controls

- (void)startEditing
{
    _editing = YES;
    
	// start editing
	if ( !_textField && ADKEditableTableViewCellEditTitle ) {
		// set it up
		CGRect tmpFrame = self.textLabel.frame;
        CGFloat tmpNewWidth = 150;
        
        tmpFrame.size.width = tmpNewWidth;
		tmpFrame.origin.y += 1;
		UITextField *tmpTextField = [[UITextField alloc] initWithFrame:tmpFrame];
		[tmpTextField setText:self.textLabel.text];
		[tmpTextField setDelegate:self];
		[tmpTextField setFont:self.textLabel.font];
		[tmpTextField setTextColor:[UIColor whiteColor]];

        if ( ADKEditableTableViewCellEditDetails ) {
            [tmpTextField setReturnKeyType:UIReturnKeyNext];
        } else {
            [tmpTextField setReturnKeyType:UIReturnKeyDone];
        }
		
        [self.contentView addSubview:tmpTextField];
		[self.textLabel setAlpha:0.0f];
        _textField = tmpTextField;
	}
	
	if ( !_detailTextField && ADKEditableTableViewCellEditDetails ) {
		// set it up
		CGRect tmpFrame = self.detailTextLabel.frame;
		tmpFrame.size.width += 100;
        tmpFrame.origin.x -= 100;
		tmpFrame.origin.y += 1;
		UITextField *tmpTextField = [[UITextField alloc] initWithFrame:tmpFrame];
		[tmpTextField setText:self.detailTextLabel.text];
		[tmpTextField setDelegate:self];
		[tmpTextField setFont:self.detailTextLabel.font];
		[tmpTextField setTextColor:self.detailTextLabel.textColor];
		[tmpTextField setReturnKeyType:UIReturnKeyDone];
        [tmpTextField setTextAlignment:NSTextAlignmentRight];
		[self.contentView addSubview:tmpTextField];
		[self.detailTextLabel setAlpha:0.0f];
        _detailTextField = tmpTextField;
	} 
}

- (void)stopEditing
{
    if ( self.textField ) {

        // save changes
        self.clip.title = self.textField.text;
        self.textLabel.text = self.textField.text;
        [self.textLabel setNeedsDisplay]; // ?
        
        // show the text label again
        [self.textLabel setHidden:NO];
        [self.textLabel setAlpha:1.0f];

        // [self.textLabel setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.2f]];

		// remove the editing field
		[self.textField removeFromSuperview];
		self.textField = nil;
	}
	
	if ( self.detailTextField ) { // shouldn't hit this

        NSAssert(NO, @"wat");
        
        // save changes
        self.clip.description = self.detailTextField.text;
        self.detailTextLabel.text = self.detailTextField.text;
        
        // show the text label again
        [self.detailTextLabel setHidden:NO];
        [self.detailTextLabel setAlpha:1.0f];
        
		// remove the editing field
		[self.detailTextField removeFromSuperview];
		self.detailTextField = nil;
	}
    
    // clear the flag
    _editing = NO;
}

#pragma mark - Property Overrides
- (void)setClip:(ADKClip *)clip
{
    if ( clip != self.clip ) {
        _clip = clip;
    }

    if ( self.clip.title && self.clip.title.length > 0 ) {
        self.textLabel.text = self.clip.title;
    } else if ( self.clip.date ) {
        // reusable date formatter for details
        static NSDateFormatter *dateFormatter = nil;
        if ( !dateFormatter ) {
            // not set up yet
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        }
        self.textLabel.text = [dateFormatter stringFromDate:self.clip.date];
    } else {
        self.textLabel.text = @"untitled clip";
    }
    
    // if we have a detail label
    if ( self.detailTextLabel ) {
        if ( self.clip.description.length > 0 ) {
            self.detailTextLabel.text = self.clip.description;
        } else if ( self.clip.duration > 0 ) {
            // reusable number formatter
            static NSNumberFormatter *numberFormatter = nil;
            if (!numberFormatter) {
                numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setMaximumFractionDigits:2]; // up to two digits on the right
                [numberFormatter setMinimumIntegerDigits:1]; // at least one digit on the left
            }
            self.detailTextLabel.text = [NSString stringWithFormat:@"%@ s",[numberFormatter stringFromNumber:[NSNumber numberWithFloat:self.clip.duration]]];
        } else {
            // no description, no date. nothing.
            self.detailTextLabel.text = @" ";
        }
    }
    
    UIImage *tmpImage = clip.thumbnail;
    if ( tmpImage ) {
        [self.imageView setImage:tmpImage];
    }
    
    return;
}

#pragma mark - Cell Stuff

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	if ( selected && !_editing ) {
		[self startEditing];
		[self.textField becomeFirstResponder];
	} else if ( !selected && _editing ) {
            [self stopEditing];
	}
}

//- (void)didTransitionToState:(UITableViewCellStateMask)state
//{
//	[super didTransitionToState:state];
//	
//	if ( state == UITableViewCellStateEditingMask ) {
//		[self startEditing];
//	}
//}
//
//- (void)willTransitionToState:(UITableViewCellStateMask)state
//{
//	[super willTransitionToState:state];
//	
//	if ( state == UITableViewCellStateDefaultMask ) {
//		[self stopEditing];
//	}
//}

#pragma mark - Text Field Delegate

//- (void)textFieldDidBeginEditing:(UITextField *)textField
//{
//    // if we're faking an empty field, clear it to start from scratch.
//    if ( [textField.text isEqualToString:@" "] )
//        textField.text = nil;
//}

//- (void)textFieldDidEndEditing:(UITextField *)textField
//{
//	// do something with it
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ( textField == self.textField && ADKEditableTableViewCellEditDetails ) {
		[_detailTextField becomeFirstResponder];
	} else {
        [textField resignFirstResponder];
		[self stopEditing];
        [self setSelected:NO animated:YES];
	}
	return NO;
}

@end
