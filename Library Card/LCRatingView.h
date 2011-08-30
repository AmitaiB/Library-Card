//
//  LCRatingView.h
//  Library Card
//
//  Created by Will Barton on 8/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LCRatingView;

@protocol LCRatingViewDelegate
- (void)ratingView:(LCRatingView *)rateView ratingDidChange:(float)rating;
@end

@interface LCRatingView : UIView 

@property (nonatomic, retain) UIImage * defaultImage;
@property (nonatomic, retain) UIImage * selectedImage;
@property (nonatomic, retain) UIImage * halfSelectedImage;
@property (nonatomic) float rating;
@property (nonatomic) BOOL editable;
@property (nonatomic) NSInteger maxRating;
@property (nonatomic, assign) IBOutlet id <LCRatingViewDelegate> delegate;
@property (nonatomic) NSInteger margin;
@property (nonatomic) NSInteger spacing;


@end
