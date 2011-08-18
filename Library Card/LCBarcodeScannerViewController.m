//
//  LCBarcodeScannerViewController.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


// https://www.googleapis.com/books/v1/volumes?key=AIzaSyDUhHq98cL-S1rNOGdSjiPXMbdoWMXhjXk&q=isbn+9780316289320


#import "LCBarcodeScannerViewController.h"
#import "MBProgressHUD.h"
#import "LCAppDelegate.h"
#import "LCBookLookup.h"

@interface LCBarcodeScannerViewController () <MBProgressHUDDelegate, LCBookLookupDelegate>
@property (nonatomic, retain) MBProgressHUD * progressHud;
@property (nonatomic, retain) ZBarCameraSimulator * cameraSim;
@end


@implementation LCBarcodeScannerViewController

@synthesize delegate = _delegate;
@synthesize readerView = _readerView;

@synthesize result = _result;

@synthesize cameraSim = _cameraSim;
@synthesize progressHud = _progressHud;

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
        
    // the delegate receives decode results
    self.readerView.readerDelegate = self;
    
    // you can use this to support the simulator
    if(TARGET_IPHONE_SIMULATOR) {
        self.cameraSim = [[ZBarCameraSimulator alloc] initWithViewController: self];
        self.cameraSim.readerView = self.readerView;
    }
    
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
	//self.progressHud.graceTime = 0.5;
	//self.progressHud.minShowTime = 5.0;
	
    // Add HUD to screen
    [self.view addSubview:self.progressHud];
    self.progressHud.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated {
    // Reset the result from our last lookup.
    self.result = nil;
}

- (void)viewDidAppear:(BOOL)animated {    
    [self.readerView start];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.readerView stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)help:(id)sender {
    
}

- (IBAction)cancel:(id)sender { 
    [self.delegate barcodeScannerDidFinish:self];
}

#pragma mark - ZBar Reader Delegate

- (void)readerView:(ZBarReaderView *)aReaderView
     didReadSymbols:(ZBarSymbolSet *)readSymbols
          fromImage:(UIImage *)scannedImage {

    NSMutableString * readString = [NSMutableString string];
    for(ZBarSymbol * symbol in readSymbols) {
        [readString appendString:symbol.data];
    }

    NSLog(@"Read String: %@", readString);
    
    [self lookupISBN:readString];
}

#pragma mark - ISBN Lookups

- (void)lookupISBN:(NSString *)isbn {
    
    LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
    bookLookup.delegate = self;
    [bookLookup lookupISBN:isbn];
    
    [self.progressHud show:YES];
}

#pragma mark - Lookup Delegate 

- (void)bookLookupFoundBook:(NSDictionary *)bookInfo {
    [self.progressHud hide:YES];

    self.result = bookInfo;
    [self.delegate barcodeScannerDidFinish:self];
}

- (void)bookLookupFailedWithError:(NSError *)error {
    [self.progressHud hide:YES];

    Alert(nil, @"Unable to find book.", @"OK", nil);
    [self.delegate barcodeScannerDidFinish:self];
}

#pragma mark - HUD Delegate
- (void)hudWasHidden {
    [self.progressHud removeFromSuperview];
}

@end
