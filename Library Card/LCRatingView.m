//
//  LCRatingView.m
//  Library Card
//
//  Created by Will Barton on 8/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCRatingView.h"

@interface LCRatingView ()

@property (nonatomic, retain) NSMutableArray * _imageViews;

- (void)handleTouchAtLocation:(CGPoint)touchLocation;

@end

@implementation LCRatingView

@synthesize defaultImage = _defaultImage;
@synthesize halfSelectedImage = _halfSelectedImage;
@synthesize selectedImage = _selectedImage;
@synthesize rating = _rating;
@synthesize editable = _editable;
@synthesize maxRating = _maxRating;
@synthesize delegate = _delegate;
@synthesize margin = _margin;
@synthesize spacing = _spacing;

@synthesize _imageViews = __imageViews;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self._imageViews = [NSMutableArray array];
        self.rating = 0;
        self.editable = YES;
        self.maxRating = 5;
        self.margin = 0;
        self.spacing = 0;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self._imageViews = [NSMutableArray array];
        self.rating = 0;
        self.editable = YES;
        self.maxRating = 5;
        self.margin = 0;
        self.spacing = 0;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)refresh {
    for (UIImageView * imageView in self._imageViews) {
        NSInteger index = [self._imageViews indexOfObject:imageView];
        if (_rating >= index + 1)
            imageView.image = self.selectedImage;
        else if (_rating > index)
            imageView.image = self.halfSelectedImage;
        else
            imageView.image = self.defaultImage;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.defaultImage == nil) 
        return;
    
    CGSize minSize = CGSizeMake(28, 28);
    
    float desiredImageWidth = ((self.frame.size.width - 
                                (self.margin * 2) - (self.spacing * self._imageViews.count)) 
                               / self._imageViews.count);
    float imageWidth = MAX(minSize.width, desiredImageWidth);
    float imageHeight = MAX(minSize.height, self.frame.size.height);
    
    for (UIImageView * imageView in self._imageViews) {
        NSInteger index = [self._imageViews indexOfObject:imageView];
        
        CGRect imageFrame = CGRectMake(self.margin + index * (self.spacing + imageWidth), 
                                       0, imageWidth, imageHeight);
        imageView.frame = imageFrame;
    }    
    
}

- (void)setMaxRating:(int)maxRating {
    _maxRating = maxRating;
    
    // Remove old image views
    for (UIImageView * imageView in self._imageViews)
        [imageView removeFromSuperview];
    [self._imageViews removeAllObjects];
    
    // Add new image views
    for(int i = 0; i < maxRating; ++i) {
        UIImageView * imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self._imageViews addObject:imageView];
        [self addSubview:imageView];
    }
    
    // Relayout and refresh
    [self setNeedsLayout];
    [self refresh];
}

- (void)setDefaultImage:(UIImage *)defaultImage {
    _defaultImage = defaultImage;
    [self refresh];
}

- (void)setHalfSelectedImage:(UIImage *)halfSelectedImage {
    halfSelectedImage = halfSelectedImage;
    [self refresh];
}

- (void)setSelectedImage:(UIImage *)selectedImage {
    _selectedImage = selectedImage;
    [self refresh];
}

- (void)setRating:(float)rating {
    _rating = rating;
    [self refresh];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.delegate ratingView:self ratingDidChange:self.rating];
}

- (void)handleTouchAtLocation:(CGPoint)touchLocation {
    if (!self.editable) 
        return;
    
    self.rating = 0;
    NSLog(@"Touch Location: %f, image views: %@", touchLocation.x, self._imageViews);

    for (UIImageView * imageView in self._imageViews) {
        NSInteger index = [self._imageViews indexOfObject:imageView];

        if (touchLocation.x > imageView.frame.origin.x) {
            self.rating = index + 1;
            NSLog(@"Rating: %f", self.rating);
        }
    }
    
    [self refresh];
}



@end
