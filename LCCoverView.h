//
//  LCCoverView.h
//  Library Card
//
//  Created by Will Barton on 8/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCBookLookup.h"
#import "Book.h"

@interface LCCoverView : UIView <LCBookLookupDelegate>

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) Book * book;
@property (nonatomic, retain) IBOutlet UIImageView * imageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicatorView;

- (void)update;
- (void)downloadCover;

@end
