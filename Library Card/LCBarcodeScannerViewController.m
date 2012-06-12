//
//  LCBarcodeScannerViewController.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


// https://www.googleapis.com/books/v1/volumes?key=AIzaSyDUhHq98cL-S1rNOGdSjiPXMbdoWMXhjXk&q=isbn+9780316289320


#import "LCBarcodeScannerViewController.h"
#import "LCSearchResultsTableViewController.h"
#import "MBProgressHUD.h"
#import "LCAppDelegate.h"
#import "LCBookLookup.h"


@interface LCBarcodeScannerViewController ()
@property (nonatomic, retain) MBProgressHUD * progressHud;
@property (nonatomic, retain) ZBarCameraSimulator * cameraSim;

- (void)configureReader;
- (void)fadeOutTipLabel;
- (void)fadeInTipLabel;
- (void)showBarcodeNotScanningTip;
@end


@implementation LCBarcodeScannerViewController

@synthesize delegate = _delegate;
@synthesize readerView = _readerView;
@synthesize overlayView = _overlayView;
@synthesize tipLabel = _tipLabel;
@synthesize helperView = _helperView;

@synthesize result = _result;

@synthesize cameraSim = _cameraSim;
@synthesize progressHud = _progressHud;

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self configureReader];
    
}

- (void)viewWillAppear:(BOOL)animated {
    // Reset the result from our last lookup.
    self.result = nil;
    self.tipLabel.text = nil;

    [self configureReader];

    [self.readerView willRotateToInterfaceOrientation:self.interfaceOrientation
                                        duration:0];
    
    [self.readerView performSelector:@selector(start)
                          withObject:nil
                          afterDelay:.001];

    if (![[UIDevice currentDevice] supportsCapability:UIDeviceAutoFocusCameraCapability]) {
        self.tipLabel.text = @"No autofocus camera.\nBarcodes may not be detected.";
        [self performSelector:@selector(fadeOutTipLabel)
                   withObject:nil
                   afterDelay:4];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {    
    [self.readerView start];
    [self performSelector:@selector(showBarcodeNotScanningTip)
               withObject:nil
               afterDelay:5];
    

}

- (void) viewWillDisappear:(BOOL)animated {
    [self.readerView stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                 duration:(NSTimeInterval)duration {
    [self.readerView willRotateToInterfaceOrientation:interfaceOrientation
                                        duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [self.readerView setNeedsLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [self.readerView willRotateToInterfaceOrientation:self.interfaceOrientation
                                             duration:0];
    [self.readerView setNeedsLayout];
}

- (void)configureReader {
 
    // the delegate receives decode results
    self.readerView.readerDelegate = self;
    
    // you can use this to support the simulator
    if(TARGET_IPHONE_SIMULATOR) {
        self.cameraSim = [[ZBarCameraSimulator alloc] initWithViewController: self];
        self.cameraSim.readerView = self.readerView;
    }
}

- (void)fadeOutTipLabel {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:2];
    self.tipLabel.alpha = 0;
    self.tipLabel.text = @"";
    [UIView commitAnimations];
}

- (void)fadeInTipLabel {
    
    self.tipLabel.alpha = 0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:2];
    self.tipLabel.alpha = 1;
    [UIView commitAnimations];

}

- (void)showBarcodeNotScanningTip {
    self.tipLabel.text = @"No barcode detected.\nMake sure to avoid glare and shadows.";
    [self fadeInTipLabel];
}

- (IBAction)help:(id)sender {
    
}

- (IBAction)cancel:(id)sender { 
    // If we don't nil the reader's delegate, we get zombies.
    self.readerView.readerDelegate = nil;
    [self.delegate barcodeScannerDidCancel:self];
}

- (IBAction)dismiss:(id)sender {
    // If we don't nil the reader's delegate, we get zombies.
    self.readerView.readerDelegate = nil;
    [self.delegate barcodeScannerDidDismiss:self];
}

#pragma mark - ZBar Reader Delegate

- (void)readerView:(ZBarReaderView *)aReaderView
     didReadSymbols:(ZBarSymbolSet *)readSymbols
          fromImage:(UIImage *)scannedImage {

    NSMutableString * readString = [NSMutableString string];
    for(ZBarSymbol * symbol in readSymbols) {
        [readString appendString:symbol.data];
    }

    DEBUG(@"Read String: %@", readString);
    
    self.result = readString;
    [self.delegate barcodeScannerDidFinish:self];

    // Leave the lookups to the book table view.
    // [self lookupISBN:readString];
}


@end
