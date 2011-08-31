//
//  LCBookViewController.m
//  Library Card
//
//  Created by Will Barton on 8/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookViewController.h"
#import "LCBarcodeScannerViewController.h"
#import "LCBookLookup.h"
#import "LCAppDelegate.h"

#import <Twitter/Twitter.h>

@interface LCBookViewController () <UITextFieldDelegate, LCBarcodeScannerDelegate, LCBookLookupDelegate, LCRatingViewDelegate>
- (void)endEditing;
- (void)updateFromModel;
@end


@implementation LCBookViewController

@synthesize book = _book;

@synthesize cameraButton = _cameraButton;
@synthesize helpButton = _helpButton;
@synthesize tweetButton = _tweetButton;

@synthesize coverImageView = _coverImageView;
@synthesize titleField = _titleField;
@synthesize authorField = _authorField; 
@synthesize publisherField = _publisherField;
@synthesize dateField;
@synthesize isbn13Field = _isbn13Field;
@synthesize pagesField = _pagesField;

@synthesize statusControl = _statusControl;
@synthesize ratingView = _ratingView;
@synthesize textView = _textView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"card.png"]];

    // Set up the rating view
    self.ratingView.defaultImage = [UIImage imageNamed:@"star_blank.png"];
    self.ratingView.selectedImage = [UIImage imageNamed:@"star.png"];
    self.ratingView.halfSelectedImage = [UIImage imageNamed:@"star_half.png"];
    
    if (self.book == nil) {
        // If we haven't gotten a book, we need to get one. Pop up the barcode scanner.
        [self performSegueWithIdentifier:@"scanBarcode" sender:self];
    }
    
    [self updateFromModel];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIKeyboardWillHideNotification];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.tweetButton.enabled = NO;
    if ([TWTweetComposeViewController canSendTweet])
        self.tweetButton.enabled = YES;
        
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog( @"In viewWillDisappear" );
    
    [super viewWillDisappear:animated];
    [self.view.window endEditing:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];

    //    if (self.book.title == nil || [self.book.title isEqualToString:@""]) {
    //        [self.book.managedObjectContext rollback];
    //    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"scanBarcode"]) {
        LCBarcodeScannerViewController * detailViewController = [segue destinationViewController];
        detailViewController.delegate = self;
    }
}

- (void)updateFromModel {
    if (self.book == nil)
        return;
    
    self.titleField.text = self.book.title;
    self.authorField.text = self.book.authors;
    self.publisherField.text = self.book.publisher;
    self.pagesField.text = [self.book.pages stringValue];
    self.isbn13Field.text = self.book.isbn13;
    
    NSLog(@"Cover Path: %@", pathToCoverForISBN(self.book.isbn13));
    self.coverImageView.image = [UIImage imageNamed:pathToCoverForISBN(self.book.isbn13)];
    self.coverImageView.layer.shadowColor = [UIColor purpleColor].CGColor;
    self.coverImageView.layer.shadowOffset = CGSizeMake(0, 1);
    self.coverImageView.layer.shadowOpacity = 1;
    self.coverImageView.layer.shadowRadius = 1.0;

    self.statusControl.selectedSegmentIndex = [self.book.status integerValue];
    self.ratingView.rating = [self.book.rating floatValue];
    
    self.title = self.book.title;
    
    self.ratingView.hidden = YES;
    if ([self.book.status integerValue] == kReadStatus)
        self.ratingView.hidden = NO;

    // self.navigationItem.title = self.book.title;
        
}

#pragma mark - Status Control

- (IBAction)statusControlChanged:(id)sender {
    self.book.status = [NSNumber numberWithInteger:self.statusControl.selectedSegmentIndex];
    [self.book save];
    [self updateFromModel];
}

#pragma mark - Barcode Delegate

- (void)barcodeScannerDidFinish:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    
    if (barcodeScannerViewController.result != nil) {
        
        if (self.book == nil) {
            // If the book is nil, create it.
            NSManagedObjectContext * managedObjectContext = ((LCAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
            self.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                                      inManagedObjectContext:managedObjectContext];
        }
        
        NSDictionary * bookInfo = barcodeScannerViewController.result;
        
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
        
        // XXX: Set up some kind of progress indicator image
        LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
        bookLookup.delegate = self;
        [bookLookup downloadCoverImage:self.book.thumbnailUrl forISBN:self.book.isbn13];
        
        [self.book save];
        [self updateFromModel];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Book Lookup Delegate

- (void)bookLookupFailedWithError:(NSError *)error {
    
}

- (void)bookLookupDownloadedCover {
    
}

#pragma mark - UITextField Delegate


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

@end
