//
//  LCCoverView.m
//  Library Card
//
//  Created by Will Barton on 8/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCCoverView.h"

@interface LCCoverView (Private)
- (void)downloadCoverWithOverwrite:(BOOL)overwrite;
@end

@implementation LCCoverView

@dynamic image;
@synthesize book = _book;
@synthesize imageView = _imageView;
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    
    if (self.image == nil)
        self.image = [UIImage imageNamed:@"cover.png"];
    
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOffset = CGSizeMake(1, 1);
    self.imageView.layer.shadowOpacity = 0.5;
    self.imageView.layer.shadowRadius = 5.0;
    
    self.activityIndicatorView.hidden = YES;
    
}

- (UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)update {
    // Reload the cover image.
    NSString * coverPath = pathToCoverForISBN(self.book.isbn13);
    NSLog(@"Cover Path: %@", coverPath);
    
    // If the file exists, don't re-download it.
    if (![[NSFileManager defaultManager] fileExistsAtPath:coverPath])
        return;

    self.image = [UIImage imageWithContentsOfFile:coverPath];
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOffset = CGSizeMake(1, 1);
    self.imageView.layer.shadowOpacity = 0.5;
    self.imageView.layer.shadowRadius = 5.0;
}

- (void)downloadCover {
    [self downloadCoverWithOverwrite:NO];
}

- (void)downloadCoverWithOverwrite:(BOOL)overwrite {
    
    NSString * coverPath = pathToCoverForISBN(self.book.isbn13);
    
    // If the file exists, don't re-download it.
    if ([[NSFileManager defaultManager] fileExistsAtPath:coverPath] && !overwrite)
        return;
    
    LCBookLookup * bookLookup = [[LCBookLookup alloc] init];
    bookLookup.delegate = self;

    [self.activityIndicatorView startAnimating];
    self.activityIndicatorView.hidden = NO;
    self.image = [UIImage imageNamed:@"blank_cover.png"];

    // If there is a thumbnail path already attached to the book, that's fine. Otherwise, find one, and return (this method will be called again once there is a successful lookup.
    if (self.book.thumbnailUrl == nil) {
        [bookLookup lookupISBN:self.book.isbn13];
        return;
    }
    
    [bookLookup downloadCoverImage:self.book.thumbnailUrl forISBN:self.book.isbn13];
}

#pragma mark - Book Lookup Delegate

- (void)bookLookupFailedWithError:(NSError *)error {
    Alert(@"Unable to Download Cover", @"Please check the ISBN or try again later.", @"OK", nil);
    
    self.image = [UIImage imageNamed:@"cover.png"];
    [self.activityIndicatorView stopAnimating];
    self.activityIndicatorView.hidden = YES;
}

- (void)bookLookupFoundBook:(NSDictionary *)bookInfo {
    self.book.thumbnailUrl = [bookInfo objectForKey:@"thumbnailUrl"]; 
    
    // Now, if we got a thumbnail URL, try again to download the cover.
    // If we did not, pass through, since we don't want to get stuck in a loop.
    // Use the overwrite method here, since, if we've made it this far, we want 
    // to overwrite whatever is there anyway.
    if (self.book.thumbnailUrl != nil)
        [self downloadCoverWithOverwrite:YES];
    
}

- (void)bookLookupDownloadedCover {
    [self update];
    [self.activityIndicatorView stopAnimating];
    self.activityIndicatorView.hidden = YES;
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSInteger touchesInCover = 0;
    NSLog(@"Touches: %@", touches);
    
    for (UITouch * touch in touches) {
        if (CGRectContainsPoint([self.imageView frame], [touch locationInView:self])) {
            NSLog(@"Touches ended in Cover Image");
            touchesInCover++;
        }
    }
    
    NSLog(@"Number of touches in cover: %d", touchesInCover);

    if ((touchesInCover == 1) && (!self.activityIndicatorView.isAnimating))
        [self downloadCover];
    else if ((touchesInCover > 1) && (!self.activityIndicatorView.isAnimating))
        [self downloadCoverWithOverwrite:YES];

}

@end
