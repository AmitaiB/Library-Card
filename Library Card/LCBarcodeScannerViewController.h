//
//  LCBarcodeScannerViewController.h
//  Library Card
//
//  Created by Will Barton on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBarSDK.h"

@class LCBarcodeScannerViewController;

@protocol LCBarcodeScannerDelegate
- (void)barcodeScannerDidFinish:(LCBarcodeScannerViewController *)barcodeScannerViewController; 
@end

@interface LCBarcodeScannerViewController : UIViewController <ZBarReaderViewDelegate>

@property (nonatomic, retain) IBOutlet id delegate;
@property (nonatomic, retain) IBOutlet ZBarReaderView * readerView;

@property (nonatomic, retain) id result;

- (void)lookupISBN:(NSString *)isbn;

@end
