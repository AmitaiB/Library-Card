//
//  LCBookTableViewController.m
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookListTableViewController.h"
#import "LCBookTableViewController.h"
#import "LCBarcodeScannerViewController.h"
#import "LCSearchResultsTableViewController.h"
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

@interface LCBookTableViewController () <UITextFieldDelegate, LCBarcodeScannerDelegate, LCRatingViewDelegate, LCBookLookupDelegate, MBProgressHUDDelegate, LCSearchResultsDelegate> {
    @private
    BOOL _textViewSizeIsUpdating;
}

@property (strong, nonatomic) UIPopoverController * masterPopoverController;
@property (nonatomic, retain) MBProgressHUD * progressHud;

- (void)configureCameraButton;
- (void)handleTapBehind:(UITapGestureRecognizer *)sender;

- (void)updateFromModel;
- (void)endEditing;
- (void)lookupISBN:(NSString *)isbn;
- (void)foundBook:(NSDictionary *)bookInfo;

- (CGSize)textViewSize:(UITextView*)textView;
- (void)setContentViewSize:(UIView *)contentView;
- (void)setTextViewSize:(UITextView*)textView;

- (NSInteger)translateSection:(NSInteger)section;
- (NSIndexPath *)translateIndexPath:(NSIndexPath *)indexPath;
- (void)searchResultsControllerSelectedBook:(NSDictionary *)bookInfo;
@end


@implementation LCBookTableViewController

@synthesize book = _book;

@synthesize cameraButton = _cameraButton;
@synthesize helpButton = _helpButton;
@synthesize tweetButton = _tweetButton;
@synthesize fetchButton = _fetchButton;
@synthesize addButton = _addButton;

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

@synthesize masterPopoverController = _masterPopoverController;
@synthesize progressHud = _progressHud;

@synthesize tapBehindRecognizer = _tapBehindRecognizer;

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
        
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reload:) 
                                                 name:@"RefreshAllViews" 
                                               object:[[UIApplication sharedApplication] delegate]];

    // Set up the rating view
    self.ratingView.defaultImage = [UIImage imageNamed:@"star_blank.png"];
    self.ratingView.selectedImage = [UIImage imageNamed:@"star.png"];
    self.ratingView.halfSelectedImage = [UIImage imageNamed:@"star_half.png"];
    
    if (self.book == nil 
        && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone 
#if !(TARGET_IPHONE_SIMULATOR)
        && [[UIDevice currentDevice] supportsCapability:UIDeviceAutoFocusCameraCapability]
#endif
        ) {
        // If we haven't gotten a book, we need to get one. Pop up the barcode scanner only if autofocus is supported.
        [self performSegueWithIdentifier:@"scanBarcode" sender:self];
    }
    
    [self configureCameraButton];
            
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
    
    // Add a shadow under the titleField
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.titleField.layer.shadowOpacity = 1.0;   
        self.titleField.layer.shadowRadius = 0.0;
        self.titleField.layer.shadowColor = [UIColor whiteColor].CGColor;
        self.titleField.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    } else {
        self.titleField.layer.shadowOpacity = 1.0;   
        self.titleField.layer.shadowRadius = 0.0;
        self.titleField.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        self.titleField.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    }
        
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillHideNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    self.tweetButton.enabled = NO;
    if ([TWTweetComposeViewController canSendTweet])
        self.tweetButton.enabled = YES;

    [self updateFromModel];

    self.coverView.book = self.book;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        self.tapBehindRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
        [self.tapBehindRecognizer setNumberOfTapsRequired:1];
        self.tapBehindRecognizer.cancelsTouchesInView = NO;
        [self.view.window addGestureRecognizer:self.tapBehindRecognizer];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view.window endEditing:YES];
    [self.view.window removeGestureRecognizer:self.tapBehindRecognizer];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"scanBarcode"]) {
        LCBarcodeScannerViewController * detailViewController = [segue destinationViewController];
        detailViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"showSearchResults"]) {
        UINavigationController * navController = [segue destinationViewController];
        LCSearchResultsTableViewController * detailViewController = (LCSearchResultsTableViewController *)navController.topViewController;
        detailViewController.delegate = self;
        
        // Hand off the book lookup to the search controller
        detailViewController.bookLookup = (LCBookLookup *)sender;
        ((LCBookLookup *)sender).delegate = detailViewController;
    }
}

- (void)configureCameraButton {
#if !(TARGET_IPHONE_SIMULATOR)
    if (![[UIDevice currentDevice] supportsCapability:UIDeviceCameraCapability])
        // If a camera is supported on this device, allow the camera
        self.cameraButton.enabled = NO;
    else
#endif
        self.cameraButton.enabled = YES;
}

- (void)updateFromModel {
    
    if (self.book == nil) {
        self.navigationItem.prompt = @"Enter title, author, or ISBN to search";

        self.titleField.text = nil;
        self.authorField.text = nil;
        self.publisherField.text = nil;
        self.pagesField.text = nil;
        self.isbn13Field.text = nil;
        self.datePublishedField.text = nil;
        self.dateReadField.text = nil;
        self.bookmarkField.text = nil;
        self.textView.text = nil;
        
        self.coverView.book = nil;
        [self.coverView update];
        
        self.statusControl.selectedSegmentIndex = kToReadStatus;
        self.ratingView.rating = 0.0;
        
        self.title = nil;
        
        // self.ratingView.editable = NO;
        // if ([self.book.status integerValue] == kReadStatus)
        //    self.ratingView.editable = YES;
        
        // self.navigationItem.title = self.book.title;
        
    } else {
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
        
        // self.ratingView.editable = NO;
        // if ([self.book.status integerValue] == kReadStatus)
        //    self.ratingView.editable = YES;
        
        // self.navigationItem.title = self.book.title;

    }
    
    DEBUG(@"Updated table view data from model.");
    [self.tableView reloadData];
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender {
    DEBUG(@"Handling Tap Behind");
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
        
        //Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
        
        if (![self.view pointInside:[self.navigationController.view convertPoint:location fromView:self.view.window] withEvent:nil] &&
            ![self.view pointInside:[self.navigationController.toolbar convertPoint:location fromView:self.view.window] withEvent:nil]) {
            [self dismissModalViewControllerAnimated:YES];
            [self.view.window removeGestureRecognizer:sender];
        }
    }
}

// this listens for the notification that the app delegate has processed new changes from iCloud
// it then decides if it wants to reload the view based on whether or not the recipe shown in the
// detail view is impacted by those changes.
// Basically it trolls through the notification userInfo to see if our recipe or its photo was changed
- (void)reloadRecipe:(NSNotification*)note {
    NSDictionary* ui = [note userInfo];
    NSManagedObjectID * bookID = [self.book objectID];
    // NSManagedObjectID * photoID = [recipe.image objectID];
    
    if (bookID) {
        BOOL shouldReload = ([ui objectForKey:NSInvalidatedAllObjectsKey] != nil);
        BOOL wasInvalidated = ([ui objectForKey:NSInvalidatedAllObjectsKey] != nil);
        
        NSString *interestingKeys[] = { NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey };
        int c = (sizeof(interestingKeys) / sizeof(NSString*));
        
        for (int i = 0; i < c; i++) {
            NSSet* collection = [ui objectForKey:interestingKeys[i]];
            if (collection) {
                for (NSManagedObject * mo in collection) {
                    // if ([[mo objectID] isEqual:bookID] || [[mo objectID] isEqual:photoID]) {
                    if ([[mo objectID] isEqual:bookID]) {
                        if ([interestingKeys[i] isEqual:NSInvalidatedObjectsKey]) {
                            wasInvalidated = YES;
                        }
                        shouldReload = YES;
                        break;
                    }
                }
            }
            if (shouldReload) {
                break;
            }
        }
        
        if (shouldReload) {
            NSManagedObjectContext *moc = self.book.managedObjectContext;
            
            if (wasInvalidated) {
                // if the object was invalidated, it is no longer a part of our MOC
                // we need a new MO for the objectID we care about
                // this generally only happens if the object was released to rc 0, the persistent store removed, or the MOC reset
                self.book = (Book *)[moc objectWithID:bookID];
            }
            
            [self viewWillAppear:NO];
        }
    }
}


#pragma mark - Getters/Setters

- (void)setBook:(Book *)book {
    if (_book != book) {
        _book = book;
        
        DEBUG(@"Setting book to %@", book);
        
        // Update the view.
        [self updateFromModel];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController 
     willHideViewController:(UIViewController *)viewController 
          withBarButtonItem:(UIBarButtonItem *)barButtonItem 
       forPopoverController:(UIPopoverController *)popoverController {
    barButtonItem.title = NSLocalizedString(@"Books", @"Books");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController 
     willShowViewController:(UIViewController *)viewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (IBAction)addBook:(id)sender {
    UINavigationController * masterNavigationController = [self.splitViewController.viewControllers objectAtIndex:0];
    LCBookListTableViewController * controller = (LCBookListTableViewController *)masterNavigationController.topViewController;
    [controller addBook:sender];
}

#pragma mark - Reading Status Control

- (IBAction)statusControlChanged:(id)sender {

    // SECTION     GLOBAL      READING     TO READ     READ
    // 0           Author      Author      Author      Author
    // 1           Book Info   Book Info   Book Info   Book Info
    // 2           Status      Status      Status      Status
    // 3           Bookmark    Bookmark                Review
    // 4           Review
     

    if (self.statusControl.selectedSegmentIndex == [self.book.status integerValue])
        return;
    
    [self.tableView beginUpdates];
    
    if ([self.book.status integerValue] != kToReadStatus)
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:3] 
                      withRowAnimation:UITableViewRowAnimationFade];        
    
    self.book.status = [NSNumber numberWithInteger:self.statusControl.selectedSegmentIndex];
    
    if ([self.book.status integerValue] != kToReadStatus)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:3] 
                      withRowAnimation:UITableViewRowAnimationFade];
        
    [self.tableView endUpdates];
    
    if ([self.book.status integerValue] != kToReadStatus)
        // Scroll the table view down 
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] 
                              atScrollPosition:UITableViewScrollPositionMiddle 
                                      animated:YES];

    [self.book save];
}

#pragma mark - ISBN Lookups

- (IBAction)find:(id)sender {
    NSMutableDictionary * searchDictionary = [NSMutableDictionary dictionary];
    if (self.titleField.text != nil)
        [searchDictionary setObject:self.titleField.text forKey:@"title"];
    
    if (self.authorField.text != nil)
        [searchDictionary setObject:self.authorField.text forKey:@"authors"];
    
    if (self.publisherField.text != nil)
        [searchDictionary setObject:self.publisherField.text forKey:@"publisher"];
    
    // Only directly match the ISBN if it's the only thing given.
    if ([searchDictionary count] == 0 && self.isbn13Field.text != nil)
        [searchDictionary setObject:self.isbn13Field.text forKey:@"isbn13"];
    
    LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
    bookLookup.delegate = self;
    [bookLookup lookupBookInfo:searchDictionary];
    
    [self.progressHud show:YES];
}

- (void)lookupISBN:(NSString *)isbn {
    LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
    bookLookup.delegate = self;
    [bookLookup lookupISBN:isbn];
    
    [self.progressHud show:YES];
}

#pragma mark - Lookup Delegate 

- (void)foundBook:(NSDictionary *)bookInfo {
    
    if (self.book == nil) {
        // If the book is nil, create it.
        NSManagedObjectContext * managedObjectContext = [((LCAppDelegate *)[[UIApplication sharedApplication] delegate]) managedObjectContext];
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
    
    DEBUG(@"Saving Book: %@", self.book);
    
    [self.book save];
    [self updateFromModel];
    [self.coverView downloadCover];

}

- (void)bookLookup:bookLookup failedWithError:(NSError *)error {
    [self.progressHud hide:YES];
    self.tableView.scrollEnabled = YES;

    Alert(@"Unable to find book", @"Please double check the title, author, or ISBN, and try again.", @"OK", nil);
    
    if (self.book == nil) {
        // If the book is nil, pop us back to the books list
        [self.navigationController popViewControllerAnimated:YES];
    }

}

- (void)bookLookupGotResults:(LCBookLookup *)bookLookup {
    [self.progressHud hide:YES];
    
    if (bookLookup.numberOfResults == 1) {
        [self foundBook:[bookLookup.results objectAtIndex:0]];
        return;
    }
    
    [self performSegueWithIdentifier:@"showSearchResults" sender:bookLookup];
}

#pragma mark - Search Delegate 

- (void)searchResultsControllerSelectedBook:(NSDictionary *)bookInfo {
    // Reuse the same method from the book lookup delegate
    [self foundBook:bookInfo];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)searchResultsControllerCanceled {
    [self dismissModalViewControllerAnimated:YES];
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
            DEBUG(@"Tweet was tweeted");
        } else if(res == TWTweetComposeViewControllerResultCancelled) {
            DEBUG(@"Tweet was NOT tweeted");
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.navigationItem.rightBarButtonItem = self.addButton;
    else
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

        if ((self.book == nil) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone))
            [self.navigationController popViewControllerAnimated:NO];
    }
    
    if (barcodeScannerViewController.result != nil) {
        [self lookupISBN:barcodeScannerViewController.result];
                
    } else if ((self.book == nil) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        // If the book is nil, pop us back to the books list
        [self.navigationController popViewControllerAnimated:NO];
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (void)barcodeScannerDidCancel:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    [self dismissModalViewControllerAnimated:YES];
    
    if ((self.book == nil) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone))
        [self.navigationController popViewControllerAnimated:NO];
    
}

- (void)barcodeScannerDidDismiss:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    [self dismissModalViewControllerAnimated:YES];    
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
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
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
        
        [self.book save];
    } else if (textField == self.pagesField) {
        self.book.pages = [NSNumber numberWithInt:[self.pagesField.text intValue]];
        [self.book save];
    } else if (textField == self.bookmarkField) {
        self.book.bookmark = [NSNumber numberWithInteger:[self.bookmarkField.text integerValue]];
        [self.book save];
    }
    
}

#pragma mark - Rating View Delegate

- (void)ratingView:(LCRatingView *)rateView ratingDidChange:(float)rating {
    self.book.rating = [NSNumber numberWithFloat:rating];
    [self.book save];
}

#pragma mark - Text View Delegate & Sizing

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (_textViewSizeIsUpdating)
        return NO;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.book.review = self.textView.text;
    [self.book save];
}

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
        DEBUG(@"Content view height: %f", contentView.frame.size.height);
        [contentView setFrame:CGRectMake(0,
                                         0,
                                         contentView.frame.size.width,
                                         (self.textView.frame.size.height+12.0f))];
        [self.tableView endUpdates];

    }
    
}

// based on the proper text view size, sets the UITextView's frame
- (void)setTextViewSize:(UITextView*)textView {

    _textViewSizeIsUpdating = YES;
    
    CGSize stringSize = [self textViewSize:textView];
    if (stringSize.height != textView.frame.size.height) {
        DEBUG(@"New Text View Height: %f", stringSize.height+10);
        [textView setFrame:CGRectMake(textView.frame.origin.x,
                                      textView.frame.origin.y,
                                      textView.frame.size.width,
                                      stringSize.height+10)];  // +10 to allow for the space above the text itself 
    }
    
    UIView * contentView = textView.superview;
    [self setContentViewSize:contentView];
    
    _textViewSizeIsUpdating = NO;
    
}

- (void)textViewDidChange:(UITextView *)textView {
    [self setTextViewSize:textView]; // set proper text view size
    UIView * contentView = textView.superview;
    [self setContentViewSize:contentView];
}

#pragma mark - Table View Delegate (Text View Sizing)

- (CGFloat)tableView:(UITableView  *)tableView heightForRowAtIndexPath:(NSIndexPath  *)indexPath {

    NSInteger section = [self translateIndexPath:indexPath].section;
     
    if (section != kBookReviewSection || indexPath.row != 2)
        return self.tableView.rowHeight;
    
    CGFloat height;
    UITextView *textView = self.textView;
    [self setTextViewSize:textView];
    height = textView.frame.size.height + 12.0;

    if (height < self.tableView.rowHeight) { 
        height = self.tableView.rowHeight;
        // NSLog(@"New Text View Height: %f", (self.tableView.rowHeight - 12.0));
        [textView setFrame:CGRectMake(textView.frame.origin.x,
                                      textView.frame.origin.y,
                                      textView.frame.size.width,
                                      self.tableView.rowHeight - 12.0)];
    }
    
    return height;
}

#pragma mark - Table View Data Source (Reading Status Hacks)

- (NSInteger)translateSection:(NSInteger)section {
    return [self translateIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]].section;
}

- (NSIndexPath *)translateIndexPath:(NSIndexPath *)indexPath {
    // Translate the given index path from a state-based table view to our global table view's data
    //    SECTION     GLOBAL      READING     TO READ     READ
    //    0           Author      Author      Author      Author
    //    1           Book Info   Book Info   Book Info   Book Info
    //    2           Status      Status      Status      Status
    //    3           Bookmark    Bookmark                Review
    //    4           Review
    // In this case we're going from one of the states to global. The only case in which the section
    // index number changes is in the READ case. In the other cases, the numberOfSections method will
    // take care of the rest.
    
    NSIndexPath * newIndexPath = indexPath;
    if ([self.book.status integerValue] == kReadStatus && indexPath.section == 3)
        newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:4];
    
    return newIndexPath;

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger numberOfSections = [super numberOfSectionsInTableView:tableView];
    
    if ([self.book.status integerValue] == kReadStatus ||
        [self.book.status integerValue] == kReadingStatus)
        // Show bookmarks
        // Hide rating/review
        numberOfSections = numberOfSections - 1;

    else if ([self.book.status integerValue] == kToReadStatus)
        // Hide bookmarks
        // Hide rating/review
        numberOfSections = numberOfSections - 2;            

    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self.book.status integerValue] == kReadStatus && section == 3)
        // We're being asked for section 4. We really want section 5.
        section = 4;
    
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView canMoveRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView cellForRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [super tableView:tableView 
  moveRowAtIndexPath:[self translateIndexPath:fromIndexPath] 
         toIndexPath:[self translateIndexPath:toIndexPath]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [super tableView:tableView titleForHeaderInSection:[self translateSection:section]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {    
    return [super tableView:tableView titleForFooterInSection:[self translateSection:section]];
}

#pragma mark - Table View Delegate (Reading Status Hacks)

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    return;
    [super tableView:tableView accessoryButtonTappedForRowWithIndexPath:[self translateIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView accessoryButtonTappedForRowWithIndexPath:[self translateIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didEndEditingRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView editingStyleForRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return [super tableView:tableView heightForFooterInSection:[self translateSection:section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [super tableView:tableView heightForHeaderInSection:[self translateSection:section]];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView indentationLevelForRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView shouldIndentWhileEditingRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    return [super tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:[self translateIndexPath:sourceIndexPath] toProposedIndexPath:[self translateIndexPath:proposedDestinationIndexPath]];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [super tableView:tableView viewForFooterInSection:[self translateSection:section]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [super tableView:tableView viewForHeaderInSection:[self translateSection:section]];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView willBeginEditingRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
    return [super tableView:tableView willDeselectRowAtIndexPath:[self translateIndexPath:indexPath]];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
    return [super tableView:tableView willSelectRowAtIndexPath:[self translateIndexPath:indexPath]];
}

@end
