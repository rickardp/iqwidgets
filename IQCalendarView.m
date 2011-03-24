//
//  IQCalendarView.m
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

#import "IQCalendarView.h"
#import "IQCalendarHeaderView.h"


@interface IQCalendarView (PrivateMethods)
- (void) setupCalendarView;
@end

@implementation IQCalendarView
@synthesize tintColor;
@synthesize headerTextColor;
@synthesize selectionColor;

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCalendarView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupCalendarView];
    }
    return self;
}

+ (Class) headerViewClass
{
    return [IQCalendarHeaderView class];
}

- (void) setupCalendarView
{
    CGRect r = self.bounds;
    self.tintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:209/255.0 alpha:1];
    self.headerTextColor = [UIColor colorWithRed:.15 green:.1 blue:0 alpha:1];
    header = (UIView*)[[[[self class] headerViewClass] alloc] initWithFrame:CGRectMake(0, 0, r.size.width, 44)];
    if([header respondsToSelector:@selector(setTintColor:)]) {
        [(id)header setTintColor:tintColor];
    }
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:header];
}

#pragma mark Disposal

- (void)dealloc
{
    [header release];
    [super dealloc];
}

#pragma mark Properties

- (void)setTintColor:(UIColor *)tc
{
    if([header respondsToSelector:@selector(setTintColor:)]) {
        [(id)header setTintColor:tc];
    }
    [tintColor release];
    tintColor = [tc retain];
}

- (void)setHeaderTextColor:(UIColor *)tc
{
    if([header respondsToSelector:@selector(setTextColor::)]) {
        [(id)header setTextColor:tc];
    }
    [headerTextColor release];
    headerTextColor = [tc retain];
}
@end



