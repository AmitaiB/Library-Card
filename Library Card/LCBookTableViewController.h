//
//  LCBookTableViewController.h
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCBarcodeScannerViewController.h"
#import "Book.h"
#import "LCRatingView.h"
#import "LCCoverView.h"

@interface LCBookTableViewController : UITableViewController <LCBarcodeScannerDelegate, UITextViewDelegate>

@property (nonatomic, retain) Book * book;

@property (nonatomic, retain) IBOutlet UIBarButtonItem * cameraButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * helpButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * tweetButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * fetchButton;

@property (nonatomic, retain) IBOutlet LCCoverView * coverView;

@property (nonatomic, retain) IBOutlet UITextField * titleField;
@property (nonatomic, retain) IBOutlet UITextField * authorField;
@property (nonatomic, retain) IBOutlet UITextField * publisherField;
@property (nonatomic, retain) IBOutlet UITextField * isbn13Field;
@property (nonatomic, retain) IBOutlet UITextField * pagesField;
@property (nonatomic, retain) IBOutlet UITextField * bookmarkField;
@property (nonatomic, retain) IBOutlet UITextField * datePublishedField;
@property (nonatomic, retain) IBOutlet UITextField * dateReadField;

@property (nonatomic, retain) IBOutlet UITableViewCell * ratingCell;
@property (nonatomic, retain) IBOutlet UITableViewCell * bookmarkCell;
@property (nonatomic, retain) IBOutlet UITableViewCell * reviewCell;
@property (nonatomic, retain) IBOutlet UITableViewCell * dateReadCell;

@property (nonatomic, retain) IBOutlet UIDatePicker * datePicker;

@property (nonatomic, retain) IBOutlet UISegmentedControl * statusControl;
@property (nonatomic, retain) IBOutlet LCRatingView * ratingView;
@property (nonatomic, retain) IBOutlet UITextView * textView;

- (IBAction)statusControlChanged:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)fetchInfo:(id)sender;

@end
