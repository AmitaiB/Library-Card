//
//  LCBookTableViewController.m
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookTableViewController.h"
#import "LCBarcodeScannerViewController.h"
#import "LCBookLookup.h"
#import "LCAppDelegate.h"
#import "LCBookLookup.h"
#import "MBProgressHUD.h"

CGFloat const kMaxFieldHeight = MAXFLOAT;

@interface LCBookTableViewController () <UITextFieldDelegate, LCBarcodeScannerDelegate, LCRatingViewDelegate, LCBookLookupDelegate, MBProgressHUDDelegate> {
    @private
    BOOL _textViewSizeIsUpdating;
}

@property (nonatomic, retain) MBProgressHUD * progressHud;

- (void)updateFromModel;
- (void)endEditing;
- (void)lookupISBN:(NSString *)isbn;

- (void)adjustStatusDependentCells;

- (CGSize)textViewSize:(UITextView*)textView;
- (void)setContentViewSize:(UIView *)contentView;
- (void)setTextViewSize:(UITextView*)textView;

@end


@implementation LCBookTableViewController

@synthesize book = _book;

@synthesize cameraButton = _cameraButton;
@synthesize helpButton = _helpButton;
@synthesize tweetButton = _tweetButton;
@synthesize fetchButton = _fetchButton;

@synthesize coverView = _coverView;

@synthesize titleField = _titleField;
@synthesize authorField = _authorField; 
@synthesize publisherField = _publisherField;
@synthesize dateField;
@synthesize isbn13Field = _isbn13Field;
@synthesize pagesField = _pagesField;
@synthesize bookmarkField = _bookmarkField;

@synthesize ratingCell = _ratingCell;
@synthesize bookmarkCell = _bookmarkCell;
@synthesize reviewCell = _reviewCell;

@synthesize statusControl = _statusControl;
@synthesize ratingView = _ratingView;
@synthesize textView = _textView;

@synthesize progressHud = _progressHud;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _textViewSizeIsUpdating = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];
        
    // Set up the rating view
    self.ratingView.defaultImage = [UIImage imageNamed:@"star_blank.png"];
    self.ratingView.selectedImage = [UIImage imageNamed:@"star.png"];
    self.ratingView.halfSelectedImage = [UIImage imageNamed:@"star_half.png"];
    
    if (self.book == nil) {
        // If we haven't gotten a book, we need to get one. Pop up the barcode scanner.
        [self performSegueWithIdentifier:@"scanBarcode" sender:self];
    }
    
    [self updateFromModel];
    
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
	
    // Add HUD to screen
    [self.view addSubview:self.progressHud];
    self.progressHud.delegate = self;

}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillHideNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.tweetButton.enabled = NO;
    if ([TWTweetComposeViewController canSendTweet])
        self.tweetButton.enabled = YES;

    self.coverView.book = self.book;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"Text View Height: %f", self.textView.frame.size.height);
    NSLog(@"Cell Height: %f", self.reviewCell.frame.size.height);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view.window endEditing:YES];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem.title = @"Back";

    if ([segue.identifier isEqualToString:@"scanBarcode"]) {
        LCBarcodeScannerViewController * detailViewController = [segue destinationViewController];
        detailViewController.delegate = self;
    }
}

- (void)updateFromModel {
    if (self.book == nil)
        return;
    
    self.navigationItem.prompt = nil;
    
    self.titleField.text = self.book.title;
    self.authorField.text = self.book.authors;
    self.publisherField.text = self.book.publisher;
    self.pagesField.text = [self.book.pages stringValue];
    self.isbn13Field.text = self.book.isbn13;
    
    self.textView.text = self.book.review;
    
    self.coverView.book = self.book;
    [self.coverView update];
    
    self.statusControl.selectedSegmentIndex = [self.book.status integerValue];
    self.ratingView.rating = [self.book.rating floatValue];
    
    self.title = self.book.title;
    
    [self adjustStatusDependentCells];
    
    // self.ratingView.editable = NO;
    // if ([self.book.status integerValue] == kReadStatus)
    //    self.ratingView.editable = YES;
    
    // self.navigationItem.title = self.book.title;
    
    if (self.book.isbn13 != nil)
        self.fetchButton.enabled = YES;
    else
        self.fetchButton.enabled = NO;

}

#pragma mark - Reading Status Control

- (IBAction)statusControlChanged:(id)sender {
    self.book.status = [NSNumber numberWithInteger:self.statusControl.selectedSegmentIndex];
    NSLog(@"New Status: %@", self.book.status);

    [self.book save];
    [self updateFromModel];
}

- (void)adjustStatusDependentCells {
    [self.tableView beginUpdates];
    switch ([self.book.status integerValue]) {
        case kReadingStatus:
            // Hide rating
            // Show bookmarks            
            self.ratingView.editable = NO;
            self.ratingView.alpha = 0.5;
            
            self.bookmarkField.enabled = YES;
            self.bookmarkField.alpha = 1.0;
            self.bookmarkCell.textLabel.alpha = 1.0;
            
            break;
            
        case kToReadStatus:
            // Hide rating
            // Hide bookmarks
            self.ratingView.editable = NO;
            self.ratingView.alpha = 0.5;

            self.bookmarkField.enabled = NO;
            self.bookmarkField.alpha = 0.5;
            self.bookmarkCell.textLabel.alpha = 0.5;
            
            break;
            
        case kReadStatus:
            // Show rating
            // Hide bookmarks
            self.ratingView.editable = YES;
            self.ratingView.alpha = 1.0;

            self.bookmarkField.enabled = NO;
            self.bookmarkField.alpha = 0.5;
            self.bookmarkCell.textLabel.alpha = 0.5;

            break;
            
        default:
            break;
    }
    [self.tableView endUpdates];
    
}

#pragma mark - ISBN Lookups

- (IBAction)fetchInfo:(id)sender {
    [self lookupISBN:self.isbn13Field.text];
}

- (void)lookupISBN:(NSString *)isbn {
    LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
    bookLookup.delegate = self;
    [bookLookup lookupISBN:isbn];
    
    [self.progressHud show:YES];
}

#pragma mark - Lookup Delegate 

- (void)bookLookupFoundBook:(NSDictionary *)bookInfo {
    [self.progressHud hide:YES];
    
    if (self.book == nil) {
        // If the book is nil, create it.
        NSManagedObjectContext * managedObjectContext = ((LCAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
        self.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                                  inManagedObjectContext:managedObjectContext];
    }
        
    // Set Book attributes
    self.book.googleId = [bookInfo objectForKey:@"googleId"];
    self.book.title = [bookInfo objectForKey:@"title"];
    self.book.authors = [bookInfo objectForKey:@"authors"];
    self.book.publisher = [bookInfo objectForKey:@"publisher"];
    self.book.pages = [bookInfo objectForKey:@"pages"];
    self.book.language = [bookInfo objectForKey:@"language"];
    self.book.thumbnailUrl = [bookInfo objectForKey:@"thumbnailUrl"]; 
    self.book.categories = [bookInfo objectForKey:@"categories"];
    self.book.isbn = [bookInfo objectForKey:@"isbn"];
    self.book.isbn13 = [bookInfo objectForKey:@"isbn13"];
    self.book.publishedDate = [bookInfo objectForKey:@"publishedDate"];
    
    NSLog(@"Saving Book: %@", self.book);
    
    [self.book save];
    [self updateFromModel];
    [self.coverView downloadCover];

}

- (void)bookLookupFailedWithError:(NSError *)error {
    [self.progressHud hide:YES];
    
    Alert(@"Unable to find book", @"Please double check the ISBN or try again later.", @"OK", nil);
    
    if (self.book == nil) {
        // If the book is nil, pop us back to the books list
        [self.navigationController popViewControllerAnimated:YES];
    }

}

#pragma mark - HUD Delegate
- (void)hudWasHidden {
    [self.progressHud removeFromSuperview];
}

#pragma mark - Barcode Delegate

- (void)barcodeScannerDidFinish:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    
    if (barcodeScannerViewController.result == nil) {
        // If the book is nil, pop us back to the books list
        [self dismissModalViewControllerAnimated:YES];

        if (self.book == nil)
            [self.navigationController popViewControllerAnimated:NO];
    }
    
    if (barcodeScannerViewController.result != nil) {
        [self lookupISBN:barcodeScannerViewController.result];
                
    } else if (self.book == nil) {
        // If the book is nil, pop us back to the books list
        [self.navigationController popViewControllerAnimated:NO];
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (void)barcodeScannerDidCancel:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    [self dismissModalViewControllerAnimated:YES];
    
    if (self.book == nil)
        [self.navigationController popViewControllerAnimated:NO];
}

- (void)barcodeScannerDidDismiss:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    [self dismissModalViewControllerAnimated:YES];
    
    if (self.book == nil)
        self.navigationItem.prompt = @"Enter ISBN to download book information.";
}


#pragma mark - Text Field Delegate


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField {
    NSLog(@"Did Should Return");
    
    [aTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)aTextField {
    NSLog(@"Did End Editing");
    
    if (aTextField == self.titleField) {
        self.book.title = self.titleField.text;
        [self.book save];
    } else if (aTextField == self.authorField) {
        self.book.authors = self.authorField.text;
        [self.book save];
    } else if (aTextField == self.publisherField) {
        self.book.publisher = self.publisherField.text;
        [self.book save];
    } else if (aTextField == self.isbn13Field) {
        self.book.isbn13 = self.isbn13Field.text;

        if (self.isbn13Field.text != nil && [[[self.isbn13Field.text componentsSeparatedByCharactersInSet:
                                               [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                                              componentsJoinedByString:@""] length] == 13)
            self.fetchButton.enabled = YES;
        else
            self.fetchButton.enabled = NO;
        
        [self.book save];
    } else if (aTextField == self.pagesField) {
        self.book.pages = [NSNumber numberWithInt:[self.pagesField.text intValue]];
        [self.book save];
    } 
    
}

#pragma mark - Rating View Delegate

- (void)ratingView:(LCRatingView *)rateView ratingDidChange:(float)rating {
    self.book.rating = [NSNumber numberWithFloat:rating];
    [self.book save];
}

#pragma mark - Social Media

- (IBAction)tweet:(id)sender {
    
    NSString * tweetText;
    if ([self.book.status integerValue] == kReadStatus)
        tweetText = [NSString stringWithFormat:@"I just finished %@, by %@.", self.book.title, self.book.authors];
    else if ([self.book.status integerValue] == kReadingStatus)
        tweetText = [NSString stringWithFormat:@"I am currently reading %@, by %@.", self.book.title, self.book.authors];
    else 
        tweetText = [NSString stringWithFormat:@"I am going to read %@, by %@.", self.book.title, self.book.authors];
    
    
    TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];
    [twitter setInitialText:tweetText];
    
    [self presentViewController:twitter animated:YES completion:nil];
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult res) {
        if(res == TWTweetComposeViewControllerResultDone) {
            NSLog(@"Tweet was tweeted");
        } else if(res == TWTweetComposeViewControllerResultCancelled) {
            NSLog(@"Tweet was NOT tweeted");
        }
        
        [self dismissModalViewControllerAnimated:YES];
    };
    
    
}

#pragma mark - Keyboard Notifications

- (void)endEditing {
    [self.view.window endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    // Show a done button in the navbar for keyboards that don't include done buttons (numeric).
    self.navigationItem.rightBarButtonItem = 
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                  target:self 
                                                  action:@selector(endEditing)];
    
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // Remove the done button.
    self.navigationItem.rightBarButtonItem = self.cameraButton;
}

#pragma mark - Text View Delegate & Sizing

// http://stackoverflow.com/questions/4015557/uitextview-in-a-uitableviewcell-smooth-auto-resize-shows-and-hides-keyboard-on-ip
// returns the proper height/size for the UITextView based on the string it contains.
// If no string, it assumes a space so that it will always have one line.
// If it has a string, and if that string ends in a newline, add a space to the calculation,
// otherwise the newline gets partially obscured when the size is used for frame heights.
- (CGSize)textViewSize:(UITextView*)textView {
    float fudgeFactor = 16.0;
    CGSize tallerSize = CGSizeMake(textView.frame.size.width-fudgeFactor, kMaxFieldHeight);
    NSString * testString = @" ";
    if ([textView.text length] > 0) {
        testString = textView.text;
        
        if ([[NSCharacterSet newlineCharacterSet] 
             characterIsMember:[testString characterAtIndex:([testString length] - 1)]]) {
            testString = [testString stringByAppendingString:@" "];
        }
    }
    CGSize stringSize = [testString sizeWithFont:textView.font constrainedToSize:tallerSize lineBreakMode:UILineBreakModeWordWrap];
    return stringSize;
}

- (void)setContentViewSize:(UIView *)contentView {
    // (1) the padding above and below the UITextView should each be 6px, so UITextView's
    // height + 12 should equal the height of the UITableViewCell
    // (2) if they are not equal, then update the height of the UITableViewCell
    if ((self.textView.frame.size.height + 12.0f) != contentView.frame.size.height) {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        [contentView setFrame:CGRectMake(0,
                                         0,
                                         contentView.frame.size.width,
                                         (self.textView.frame.size.height+12.0f))];
    }
    
}

// based on the proper text view size, sets the UITextView's frame
- (void)setTextViewSize:(UITextView*)textView {

    _textViewSizeIsUpdating = YES;
    
    CGSize stringSize = [self textViewSize:textView];
    if (stringSize.height != textView.frame.size.height) {
        NSLog(@"New Text View Height: %f", stringSize.height+10);
        [textView setFrame:CGRectMake(textView.frame.origin.x,
                                      textView.frame.origin.y,
                                      textView.frame.size.width,
                                      stringSize.height+10)];  // +10 to allow for the space above the text itself 
    }
    
    UIView * contentView = textView.superview;
    [self setContentViewSize:contentView];
    
    _textViewSizeIsUpdating = NO;
    
}


// as per: http://stackoverflow.com/questions/3749746/uitextview-in-a-uitableviewcell-smooth-auto-resize
- (void)textViewDidChange:(UITextView *)textView {
    
    [self setTextViewSize:textView]; // set proper text view size

}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (_textViewSizeIsUpdating)
        return NO;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.book.review = self.textView.text;
    [self.book save];
}

#pragma mark - Table View Delegate (Text View Sizing)

- (CGFloat)tableView:(UITableView  *)tableView heightForRowAtIndexPath:(NSIndexPath  *)indexPath {
    
    if (indexPath.section != 3)
        return self.tableView.rowHeight;
    
    CGFloat height;
    UITextView *textView = self.textView;
    [self setTextViewSize:textView];
    height = textView.frame.size.height + 12.0;

    if (height < self.tableView.rowHeight) { 
        height = self.tableView.rowHeight;
        NSLog(@"New Text View Height: %f", (self.tableView.rowHeight - 12.0));
        [textView setFrame:CGRectMake(textView.frame.origin.x,
                                      textView.frame.origin.y,
                                      textView.frame.size.width,
                                      self.tableView.rowHeight - 12.0)];
    }
    
    return height;
}

#pragma mark - Table View Data Source (Reading Status Hacks)

/*
// In order to use the new "static" tables but still show and hide rows based on selections, 
// I'm hacking the data source methods for UITableViewController.
// This is all very exceptionally ugly.

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 0;
    
    switch ([self.book.status integerValue]) {
        case kReadingStatus:
            // Hide rating
            // Show bookmarks
            // Hide review
            if (section == 2)
                numberOfRows = 2;
            else if (section == 2)
                numberOfRows = 0;

            break;
            
        case kToReadStatus:
            // Hide rating
            // Hide bookmarks
            // Hide review
            if (section == 2)
                numberOfRows = 1;
            else if (section == 3)
                numberOfRows = 0;

            break;
            
        case kReadStatus:
            // Show rating
            // Hide bookmarks
            // Show review
            if (section == 2)
                numberOfRows = 2;
            else if (section == 3)
                numberOfRows = 1;
            
            break;
            
        default:
            numberOfRows = [super tableView:tableView numberOfRowsInSection:section];
            break;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell;
    
    NSIndexPath * ratingIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    NSIndexPath * bookmarksIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    NSIndexPath * reviewIndexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    
    NSLog(@"Index Path: %@ For Status: %@", indexPath, self.book.status);
    
    switch ([self.book.status integerValue]) {
        case kReadingStatus:
            // Hide rating
            // Show bookmarks
            // Hide review
            if (indexPath.section == 1 && indexPath.row == 1)
                cell = [super tableView:tableView cellForRowAtIndexPath:bookmarksIndexPath];
            
            break;
            
        case kToReadStatus:
            // Hide rating
            // Hide bookmarks
            // Hide review
            
            break;
            
        case kReadStatus:
            // Show rating
            // Hide bookmarks
            // Show review
            
            if (indexPath.section == 1 && indexPath.row == 1)
                cell = [super tableView:tableView cellForRowAtIndexPath:ratingIndexPath];

            else if (indexPath.section == 2 && indexPath.row == 0)
                cell = [super tableView:tableView cellForRowAtIndexPath:reviewIndexPath];
            
            break;
    }

    if (cell == nil)
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    return cell;
}
*/

@end
