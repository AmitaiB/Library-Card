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

@interface LCBookTableViewController () <UITextFieldDelegate, LCBarcodeScannerDelegate, LCBookLookupDelegate>
- (void)updateFromModel;
@end


@implementation LCBookTableViewController

@synthesize book = _book;
@synthesize coverImageView = _coverImageView;
@synthesize titleField = _titleField;
@synthesize authorField = _authorField; 
@synthesize publisherField = _publisherField;
@synthesize dateField;
@synthesize locationField = _locationField;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateFromModel];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog( @"In viewWillDisappear" );

    [super viewWillDisappear:animated];
    [self.view.window endEditing:YES];
    
//    if (self.book.title == nil || [self.book.title isEqualToString:@""]) {
//        [self.book.managedObjectContext rollback];
//    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
    self.titleField.text = self.book.title;
    self.authorField.text = self.book.authors;
    self.publisherField.text = self.book.publisher;
    self.locationField.text = self.book.placeOfPublication;
    
    [self.tableView reloadData];

}

#pragma mark - Barcode Delegate

- (void)barcodeScannerDidFinish:(LCBarcodeScannerViewController *)barcodeScannerViewController {
    
    if (barcodeScannerViewController.result != nil) {

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
    } else if (aTextField == self.locationField) {
        self.book.placeOfPublication = self.locationField.text;
        [self.book save];
    } 

}


@end
