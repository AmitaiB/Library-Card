//
//  LCBarcodeScannerViewController.m
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBarcodeScannerViewController.h"

@implementation LCBarcodeScannerViewController

@synthesize delegate = _delegate;
@synthesize readerView = _readerView;
@synthesize cameraSim = _cameraSim;

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
}

@end
