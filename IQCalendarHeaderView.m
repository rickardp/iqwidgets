//
//  IQCalendarHeaderView.h
//  IQWidgets for iOS
//
//  Copyright 2011 EvolvIQ
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "IQCalendarHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation IQCalendarHeaderView
@synthesize titleLabel;

#pragma mark Initialization

- (void)setupCalendarHeaderView
{
    CGRect bd = self.bounds;
    border = [[UIView alloc] initWithFrame:CGRectMake(0, bd.size.height-1, bd.size.width, 1)];
    [self addSubview:border];
    border.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    border.backgroundColor = [UIColor blackColor];
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, bd.size.width - 80, 20)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.shadowOffset = CGSizeMake(0, -1);
    titleLabel.text = @"December 2011";
    [self addSubview:titleLabel];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCalendarHeaderView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupCalendarHeaderView];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

#pragma mark Disposal

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Initialization

- (void)setTintColor:(UIColor *)tintColor
{
    CAGradientLayer* layer = (CAGradientLayer*)self.layer;
    const CGFloat* cmpnts = CGColorGetComponents([tintColor CGColor]);
    if(cmpnts == nil) {
        static const CGFloat black[] = {0,0,0,1};
        cmpnts = black;
    }
    CGFloat colors[] = {
        cmpnts[0]+.16, cmpnts[1]+.16, cmpnts[2]+.16, 1,
        cmpnts[0], cmpnts[1], cmpnts[2], 1,
        cmpnts[0]-.12, cmpnts[1]-.12, cmpnts[2]-.12, 1,
    };
    layer.colors = [NSArray arrayWithObjects:(id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors), (id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors+4), nil];
    border.backgroundColor = [UIColor colorWithRed:colors[8] green:colors[9] blue:colors[10] alpha:1];
}

- (void)setTextColor:(UIColor *)text
{
    titleLabel.textColor = text;
}

- (void)updateLabels
{
    
}

- (void)setTitleCalendarUnits:(NSCalendarUnit)units
{
    titleCalendarUnits = units;
    [self updateLabels];
}
- (void)setCornerCalendarUnits:(NSCalendarUnit)units
{
    
}
- (void)setItemCalendarUnits:(NSCalendarUnit)units
{
    
}
- (void)setItems:(const IQCalendarHeaderItem*)items count:(NSUInteger)count cornerWidth:(CGFloat)cornerWidth startTime:(NSDate*)time animated:(BOOL)animated
{
    
}

@end
