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

// The section index within our static table of the sections related to the respective book reading statuses.
typedef enum {
    kBookAuthorSection,
    kBookInfoSection,
    kBookReadingStatusSection,
    kBookBookmarkSection,
    kBookReviewSection,
} LCBookTableSections;

NSInteger const kNumberOfSections = 5;

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

- (NSIndexPath *)shiftIndexPath:(NSIndexPath *)indexPath;

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
@synthesize isbn13Field = _isbn13Field;
@synthesize pagesField = _pagesField;
@synthesize bookmarkField = _bookmarkField;
@synthesize datePublishedField = _datePublishedField;
@synthesize dateReadField = _dateReadField;

@synthesize ratingCell = _ratingCell;
@synthesize bookmarkCell = _bookmarkCell;
@synthesize reviewCell = _reviewCell;
@synthesize dateReadCell = _dateReadCell;

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

    // Set up the Date Picker and related text fields
    UIDatePicker * datePublishedPicker = [[UIDatePicker alloc] init];
    datePublishedPicker.datePickerMode = UIDatePickerModeDate;
    [datePublishedPicker addTarget:self action:@selector(datePublishedChanged:) forControlEvents:UIControlEventValueChanged];
    self.datePublishedField.inputView = datePublishedPicker;
    
    UIDatePicker * dateReadPicker = [[UIDatePicker alloc] init];
    dateReadPicker.datePickerMode = UIDatePickerModeDate;
    [dateReadPicker addTarget:self action:@selector(dateReadChanged:) forControlEvents:UIControlEventValueChanged];
    self.dateReadField.inputView = dateReadPicker;
    
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
    self.datePublishedField.text = self.book.formattedPublishedDate;
    self.dateReadField.text = self.book.formattedDateRead;
    self.bookmarkField.text = [self.book.bookmark stringValue];
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
    //[self.tableView reloadData];
    
    /*
    if ([self.book.status integerValue] == kReadStatus ||
        [self.book.status integerValue] == kReadingStatus)
        // Show bookmarks
        // Hide rating/review
        numberOfSections = numberOfSections - 1;
    
    else if ([self.book.status integerValue] == kToReadStatus)
        // Hide bookmarks
        // Hide rating/review
        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:5] 
                       withRowAnimation:UITableViewRowAnimationTop];

    */
    
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

#pragma mark - Date Pickers

- (void)datePublishedChanged:(UIDatePicker *)datePicker {
    self.book.publishedDate = datePicker.date;
    [self.book save];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    NSString * formattedDateString = [dateFormatter stringFromDate:datePicker.date];
    
    self.datePublishedField.text = formattedDateString;
}    

- (void)dateReadChanged:(UIDatePicker *)datePicker {
    self.book.dateRead = datePicker.date;
    [self.book save];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    NSString * formattedDateString = [dateFormatter stringFromDate:datePicker.date];
    
    self.dateReadField.text = formattedDateString;
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // Set the default values for the date pickers
    if (textField == self.datePublishedField) {
        if (self.book.publishedDate != nil)
            ((UIDatePicker *)self.datePublishedField.inputView).date = self.book.publishedDate;
    } else if (textField == self.dateReadField) {
        if (self.book.dateRead != nil)
            ((UIDatePicker *)self.dateReadField.inputView).date = self.book.dateRead;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    NSLog(@"Did Should Return");
    
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"Did End Editing");
    
    if (textField == self.titleField) {
        self.book.title = self.titleField.text;
        [self.book save];
    } else if (textField == self.authorField) {
        self.book.authors = self.authorField.text;
        [self.book save];
    } else if (textField == self.publisherField) {
        self.book.publisher = self.publisherField.text;
        [self.book save];
    } else if (textField == self.isbn13Field) {
        self.book.isbn13 = self.isbn13Field.text;

        if (self.isbn13Field.text != nil && [[[self.isbn13Field.text componentsSeparatedByCharactersInSet:
                                               [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                                              componentsJoinedByString:@""] length] == 13)
            self.fetchButton.enabled = YES;
        else
            self.fetchButton.enabled = NO;
        
        [self.book save];
    } else if (textField == self.pagesField) {
        self.book.pages = [NSNumber numberWithInt:[self.pagesField.text intValue]];
        [self.book save];
    } else if (textField == self.bookmarkField) {
        self.book.bookmark = [NSNumber numberWithInt:[self.pagesField.text intValue]];
        [self.book save];
    }
    
}

#pragma mark - Rating View Delegate

- (void)ratingView:(LCRatingView *)rateView ratingDidChange:(float)rating {
    self.book.rating = [NSNumber numberWithFloat:rating];
    [self.book save];
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
        
    NSInteger section = indexPath.section;
    if ([self.book.status integerValue] == kReadStatus && section == kBookBookmarkSection)
        // We're being asked for section 4. We really want section 5.
        section = kBookBookmarkSection + 1;

    if (section != kBookReviewSection || indexPath.row != 2)
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

- (NSIndexPath *)shiftIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath * newIndexPath = indexPath;
    
    /*
     Table View looks like this:
     
     1 AUTHOR SECTION
     2 BOOK INFO SECTION
     3 STATUS SECTION
     4 BOOKMARK SECTION
     5 REVIEW SECTION
     
     We want to selectively hide the bookmark and/or review section, by shifting the
     section value of the index path as needed.
     
     In practice, this means we assume the numberOfSections method below is correct,
     and that the table view should not ask for 5 sections when there should be 4.
     In that case, the only case we have to worry about is kReadStatus, when the 
     section index 4 will refer to the review section rather than the bookmark section.
     */
    
    if ([self.book.status integerValue] == kReadStatus && indexPath.section == kBookBookmarkSection)
        // We're being asked for section 4. We really want section 5.
        newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:kBookReviewSection];

    NSLog(@"Given Section: %d New Section: %d", indexPath.section, newIndexPath.section);
    
    return newIndexPath;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger numberOfSections = [super numberOfSectionsInTableView:tableView];
    return numberOfSections;
    
    if ([self.book.status integerValue] == kReadStatus ||
        [self.book.status integerValue] == kReadingStatus)
        // Show bookmarks
        // Hide rating/review
        numberOfSections = numberOfSections - 1;

    else if ([self.book.status integerValue] == kToReadStatus)
        // Hide bookmarks
        // Hide rating/review
        numberOfSections = numberOfSections - 2;            

    
    NSLog(@"Number of sections: %d", numberOfSections);
    
    return numberOfSections;
}

/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray * sectionIndexTitles = [[super sectionIndexTitlesForTableView:tableView] mutableCopy];
    
    // XXX: This won't work. Arrays are not sorted.
    if ([self.book.status integerValue] == kReadStatus ||
        [self.book.status integerValue] == kReadingStatus) {
        // Show bookmarks
        // Hide rating/review
        // Remove the title at the review section index
        [sectionIndexTitles removeObjectAtIndex:kBookReviewSection];
    } else if ([self.book.status integerValue] == kToReadStatus) {
        // Hide bookmarks
        // Hide rating/review
        // Remove the title at the bookmark and review section indexes
        [sectionIndexTitles removeObjectAtIndex:kBookBookmarkSection];
        [sectionIndexTitles removeObjectAtIndex:kBookReviewSection];
    }
    return sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
    NSInteger section = [super tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    
    if ([self.book.status integerValue] == kReadStatus && section == kBookReviewSection)
        // We're being asked for section 4. We really want section 5.
        section = kBookReviewSection - 1;
    
    return section;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath * shiftedIndexPath = [self shiftIndexPath:indexPath];
    return [super tableView:tableView canEditRowAtIndexPath:shiftedIndexPath];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath * shiftedIndexPath = [self shiftIndexPath:indexPath];
    return [super tableView:tableView canMoveRowAtIndexPath:shiftedIndexPath];
}
*/

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath * shiftedIndexPath = [self shiftIndexPath:indexPath];
    return [super tableView:tableView cellForRowAtIndexPath:shiftedIndexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath * shiftedIndexPath = [self shiftIndexPath:indexPath];
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:shiftedIndexPath];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSIndexPath * shiftedFromIndexPath = [self shiftIndexPath:fromIndexPath];
    NSIndexPath * shiftedToIndexPath = [self shiftIndexPath:toIndexPath];
    [super tableView:tableView moveRowAtIndexPath:shiftedFromIndexPath toIndexPath:shiftedToIndexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self.book.status integerValue] == kReadStatus && section == kBookBookmarkSection)
        // We're being asked for section 4. We really want section 5.
        section = kBookBookmarkSection + 1;

    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.book.status integerValue] == kReadStatus && section == kBookBookmarkSection)
        // We're being asked for section 4. We really want section 5.
        section = kBookBookmarkSection + 1;
        
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ([self.book.status integerValue] == kReadStatus && section == kBookBookmarkSection)
        // We're being asked for section 4. We really want section 5.
        section = kBookBookmarkSection + 1;
    
    return [super tableView:tableView titleForFooterInSection:section];
}
*/

@end
