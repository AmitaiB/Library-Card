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

@interface LCBookViewController () <UITextFieldDelegate, LCBarcodeScannerDelegate, LCBookLookupDelegate, LCRatingViewDelegate>
- (void)updateFromModel;
@end


@implementation LCBookViewController

@synthesize book = _book;
@synthesize coverImageView = _coverImageView;
@synthesize titleField = _titleField;
@synthesize authorField = _authorField; 
@synthesize publisherField = _publisherField;
@synthesize dateField;
@synthesize isbn13Field = _isbn13Field;
@synthesize pagesField = _pagesField;
@synthesize ratingView = _ratingView;

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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
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
    
    self.ratingView.rating = [self.book.rating floatValue];
    
    self.title = self.book.title;
    // self.navigationItem.title = self.book.title;
        
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

@end
